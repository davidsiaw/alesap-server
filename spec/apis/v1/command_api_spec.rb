# frozen_string_literal: true

RSpec.describe CommandApi, type: :request do
  # intercept web requests
  before do
    WebMock.enable!
  end

  after do
    WebMock.disable!
  end

  # spec/fixtures/tbldump/api: 4 test song / Somebody, 1877A6 勇者 / YOASOBI (番組V), 1943B8 夜に駆ける / YOASOBI.
  # 2018A22 is deliberately missing.

  describe '/queue', :no_db_transaction do
    it 'performs a queue' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      stub = stub_request(:post, "http://order.mashup.jp/bridge/post_request.php")
        .with(body: "akey=1&ecd=4&scd=3&skey=2")
        .to_return(body: "lol")

      post '/api/v1/command/queue', params: {
        akey: 1,
        skey: 2,
        scd: 3,
        ecd: 4
      }

      expect(response.body).to eq({ result: 'ok' }.to_json)
      expect(stub).to have_been_requested
    end

    it 'rejects a code that is not in the imported dump, without calling the bridge' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      post '/api/v1/command/queue', params: { akey: 1, skey: 2, scd: 3, ecd: '2018A22' }

      expect(response).to have_http_status(:bad_request)
      expect(a_request(:post, 'http://order.mashup.jp/bridge/post_request.php')).not_to have_been_made
    end
  end

  describe '/song', :no_db_transaction do
    # The newer frontend calls /command/song; /song is kept for anything using the old path.
    %w[/api/v1/song /api/v1/command/song].each do |path|
      it "#{path} returns the song, with the 番組V marker" do
        TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
        get path, params: { code: '1877A6' }

        expect(response.parsed_body).to include('song' => '勇者【番組V】', 'artist' => 'YOASOBI', 'code' => '1877A6',
                                                'extra' => a_hash_including('song_name' => '勇者'))
      end

      it "#{path} returns 404 for a code that is not in the dump" do
        TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
        get path, params: { code: '2018A22' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "/stop" do
    it 'tries to stop the song' do
      stub = stub_request(:post, "http://order.mashup.jp/bridge/post_request.php")
        .with(body: "akey=1&scd=3&skey=2&type=2")
        .to_return(body: "lol")

      post '/api/v1/command/stop', params: {
        akey: 1,
        skey: 2,
        scd: 3
      }

      expect(response.body).to eq({ result: 'ok' }.to_json)
      expect(stub).to have_been_requested
    end
  end

  # Sent the way the frontend sends it: JSON, with a nickname the bridge doesn't need.
  describe '/pitch' do
    { 'sharp' => 3, 'flat' => 4 }.each do |direction, type|
      it "forwards #{direction} as type #{type}" do
        stub = stub_request(:post, 'http://order.mashup.jp/bridge/post_request.php')
               .with(body: "akey=1&scd=3&skey=2&type=#{type}").to_return(body: 'lol')

        post '/api/v1/command/pitch/',
             params: { nickname: 'n', akey: '1', skey: '2', scd: '3', pitch: direction }.to_json,
             headers: { 'CONTENT_TYPE' => 'application/json' }

        expect(response.body).to eq({ result: 'ok' }.to_json)
        expect(stub).to have_been_requested
      end
    end

    it 'rejects an unknown direction without calling the bridge' do
      post '/api/v1/command/pitch/',
           params: { nickname: 'n', akey: '1', skey: '2', scd: '3', pitch: 'up' }.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:bad_request)
      expect(a_request(:post, 'http://order.mashup.jp/bridge/post_request.php')).not_to have_been_made
    end
  end

  describe '/import_favourites', :no_db_transaction do
    it 'returns empty favourites and cache for unknown user' do
      get '/api/v1/command/import_favourites?nickname=nonexistent'

      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body['favourites']).to eq([])
      expect(body['cache']).to eq([])
    end

    it 'returns saved favourites for a user' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      create(:user_favourite, nickname: 'alice', song_code: '1877A6')
      create(:user_favourite, nickname: 'alice', song_code: '2018A22')

      get '/api/v1/command/import_favourites?nickname=alice'

      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body['favourites']).to eq(['1877A6', '2018A22'])
    end

    it 'returns song details in cache for codes that are in the dump' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      create(:user_favourite, nickname: 'alice', song_code: '1877A6')
      create(:user_favourite, nickname: 'alice', song_code: '2018A22')

      get '/api/v1/command/import_favourites?nickname=alice'

      expect(response.parsed_body['cache'])
        .to match([a_hash_including('code' => '1877A6', 'song' => '勇者【番組V】', 'artist' => 'YOASOBI')])
    end

    it 'does not return other users favourites' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      create(:user_favourite, nickname: 'alice', song_code: '1877A6')
      create(:user_favourite, nickname: 'bob', song_code: '2018A22')

      get '/api/v1/command/import_favourites?nickname=alice'

      body = JSON.parse(response.body)
      expect(body['favourites']).to eq(['1877A6'])
    end

    it 'returns 400 when nickname is missing' do
      get '/api/v1/command/import_favourites'

      expect(response.status).to eq 400
    end
  end

  describe "/export_favourites" do
    it 'saves favourites for a user' do
      post '/api/v1/command/export_favourites',
        params: { nickname: 'alice', data: ['1877A6', '2018A22'] }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 201
      expect(UserFavourite.where(nickname: 'alice').count).to eq 2
    end

    it 'replaces existing favourites on re-export' do
      create(:user_favourite, nickname: 'alice', song_code: 'OLD1')

      post '/api/v1/command/export_favourites',
        params: { nickname: 'alice', data: ['NEW1'] }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(UserFavourite.where(nickname: 'alice').pluck(:song_code)).to eq ['NEW1']
    end

    it 'returns 400 for invalid data' do
      post '/api/v1/command/export_favourites',
        params: { nickname: 'alice', data: 'invalid' }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 400
    end

    it 'returns 400 when nickname is missing' do
      post '/api/v1/command/export_favourites',
        params: { data: ['1877A6'] }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 400
    end
  end

  describe '/import_history', :no_db_transaction do
    it 'returns empty history and cache for unknown user' do
      get '/api/v1/command/import_history?nickname=nonexistent'

      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body['song_history']).to eq([])
      expect(body['cache']).to eq([])
    end

    it 'returns saved history for a user' do
      TbldumpImportService.new.call('spec/fixtures/tbldump/api', workers: 2, logger: Logger.new(nil))
      create(:song_history, nickname: 'alice', song_code: '1943B8',
        last_played_at: 1748131200)

      get '/api/v1/command/import_history?nickname=alice'

      body = JSON.parse(response.body)
      expect(body['song_history']).to eq([{
        'song_code' => '1943B8',
        'last_played' => 1748131200
      }])
      expect(body['cache']).to match([a_hash_including('code' => '1943B8', 'song' => '夜に駆ける', 'artist' => 'YOASOBI')])
    end

    it 'returns 400 when nickname is missing' do
      get '/api/v1/command/import_history'

      expect(response.status).to eq 400
    end
  end

  describe "/export_history" do
    it 'saves history for a user' do
      post '/api/v1/command/export_history',
        params: {
          nickname: 'alice',
          data: [
            { 'song_code' => '1943B8', 'last_played' => 1748131200 }
          ]
        }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 201
      expect(SongHistory.where(nickname: 'alice').count).to eq 1
    end

    it 'replaces existing history on re-export' do
      create(:song_history, nickname: 'alice', song_code: 'OLD1')

      post '/api/v1/command/export_history',
        params: {
          nickname: 'alice',
          data: [
            { 'song_code' => 'NEW1', 'last_played' => 1748217600 }
          ]
        }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(SongHistory.where(nickname: 'alice').pluck(:song_code)).to eq ['NEW1']
    end

    it 'saves song_count along with history' do
      post '/api/v1/command/export_history',
        params: {
          nickname: 'alice',
          data: [
            { 'song_code' => '1943B8', 'last_played' => 1748131200 }
          ],
          song_count: { '1943B8' => 5 }
        }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 201
      expect(SongCounter.where(nickname: 'alice').count).to eq 1
      expect(SongCounter.find_by(song_code: '1943B8').count).to eq 5
    end

    it 'returns 400 for invalid data' do
      post '/api/v1/command/export_history',
        params: {
          nickname: 'alice',
          data: 'invalid'
        }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 400
    end

    it 'returns 400 when nickname is missing' do
      post '/api/v1/command/export_history',
        params: {
          data: [{ 'song_code' => '1943B8', 'last_played' => 1748131200 }]
        }.to_json,
        env: { 'CONTENT_TYPE' => 'application/json' }

      expect(response.status).to eq 400
    end
  end

end
