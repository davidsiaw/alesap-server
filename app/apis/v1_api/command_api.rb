# frozen_string_literal: true

# GET command
class CommandApi < Grape::API

  # Command list
  STOP_SONG_COMMAND = 2
  PITCH_COMMANDS = { 'sharp' => 3, 'flat' => 4 }.freeze # pitch up / pitch down

  resource :command do

    resource :search do

      desc 'search for songs'
      params do
        optional :str, type: String, desc: 'search str'
        optional :page, type: Integer, desc: 'page num'
        optional :request_id, type: String, desc: 'requestid'
        optional :constraint, type: String, values: SearchService::CONSTRAINTS.keys, default: 'all',
                              desc: 'all (titles/artists/tie-ups), title, artist, or tags (genre/theme/content type)'
      end
      post do

        SearchService.new.call(params[:str], params[:page].to_i, constraint: params[:constraint])
                     .merge(request_id: params[:request_id])

      end
    end

    desc 'queue command'
    params do
      requires :akey, type: String, desc: 'akey'
      requires :skey, type: String, desc: 'skey'
      requires :scd, type: String, desc: 'scd'
      requires :ecd, type: String, desc: 'ecd'
    end
    post 'queue' do
      unless SongDataService.new.exists?(params[:ecd])
        status 400
        return { error: 'invalid song code' }
      end

      conn = Faraday::Connection.new 'http://order.mashup.jp'
      conn.post '/bridge/post_request.php' do |req|
        req.body = CGI.unescape({
          akey: params[:akey],
          skey: params[:skey],
          scd: params[:scd],
          ecd: params[:ecd]
        }.to_query)
      end

      status 200
      { result: 'ok' }
    end

    desc 'stop song command'
    params do
      requires :akey, type: String, desc: 'akey'
      requires :skey, type: String, desc: 'skey'
      requires :scd, type: String, desc: 'scd'
    end
    post 'stop' do
      conn = Faraday::Connection.new 'http://order.mashup.jp'
      conn.post '/bridge/post_request.php' do |req|
        req.body = CGI.unescape({
          akey: params[:akey],
          skey: params[:skey],
          scd: params[:scd],
          type: STOP_SONG_COMMAND
        }.to_query)
      end

      status 200
      { result: 'ok' }
    end

    desc 'change pitch command'
    params do
      requires :akey, type: String, desc: 'akey'
      requires :skey, type: String, desc: 'skey'
      requires :scd, type: String, desc: 'scd'
      requires :pitch, type: String, values: PITCH_COMMANDS.keys, desc: 'sharp (up) or flat (down)'
    end
    post 'pitch' do
      conn = Faraday::Connection.new 'http://order.mashup.jp'
      conn.post '/bridge/post_request.php' do |req|
        req.body = CGI.unescape({
          akey: params[:akey],
          skey: params[:skey],
          scd: params[:scd],
          type: PITCH_COMMANDS.fetch(params[:pitch])
        }.to_query)
      end

      status 200
      { result: 'ok' }
    end

    desc 'import favourites'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
    end
    get 'import_favourites' do
      codes = UserFavourite.where(nickname: params[:nickname]).pluck(:song_code)
      cache = SongDataService.new.build(codes)
      { favourites: codes, cache: cache }
    end

    desc 'export favourites'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
      requires :data, type: Array, desc: 'Favourites array of song codes'
    end
    post 'export_favourites' do
      codes = params[:data]
      unless codes.all? { |c| c.is_a?(String) }
        status 400
        return { error: :invalid_data }
      end

      UserFavourite.where(nickname: params[:nickname]).delete_all
      rows = codes.map { |code| { nickname: params[:nickname], song_code: code } }
      UserFavourite.insert_all(rows) if rows.any?
      { result: :ok }
    end

    desc 'import history'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
    end
    get 'import_history' do
      history = SongHistory.where(nickname: params[:nickname])
        .order(:updated_at)
        .map do |h|
          {
            song_code: h.song_code,
            last_played: h.last_played_at
          }
        end
      cache = SongDataService.new.build(history.map { |h| h[:song_code] })
      counts = SongCounter.where(nickname: params[:nickname])
      song_count = {}
      counts.each { |c| song_count[c.song_code] = c.count }
      { song_history: history, cache: cache, song_count: song_count }
    end

    desc 'export history'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
      requires :data, type: Array, desc: 'Array of history entries'
      optional :song_count, type: Hash, desc: 'Song play count hash { song_code: count }'
    end
    post 'export_history' do
      entries = params[:data]
      unless entries.all? { |e| e.is_a?(Hash) }
        status 400
        return { error: :invalid_data }
      end

      SongHistory.where(nickname: params[:nickname]).delete_all
      rows = entries.map do |entry|
        {
          nickname: params[:nickname],
          song_code: entry['song_code'],
          last_played_at: entry['last_played']
        }
      end
      SongHistory.insert_all(rows) if rows.any?

      if params[:song_count].is_a?(Hash)
        SongCounter.where(nickname: params[:nickname]).delete_all
        song_rows = params[:song_count].map do |code, count|
          {
            nickname: params[:nickname],
            song_code: code.to_s,
            count: count.to_i
          }
        end
        SongCounter.insert_all(song_rows) if song_rows.any?
      end

      { result: :ok }
    end
  end

  helpers do
    def song_data(code)
      song = SongDataService.new.build([code]).first
      return song if song

      status 404
      { error: 'not found' }
    end
  end

  # Served at both /song and /command/song: the newer frontend calls the latter.
  desc 'get song data'
  params do
    requires :code, type: String
  end
  get 'song' do
    song_data(params[:code])
  end

  resource :command do
    desc 'get song data'
    params do
      requires :code, type: String
    end
    get 'song' do
      song_data(params[:code])
    end
  end
end
