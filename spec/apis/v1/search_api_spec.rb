# frozen_string_literal: true

require 'rails_helper'

# End to end: the spec/fixtures/tbldump/search dump is imported, then POST /command/search.
#
# Songs (code: title / singer):
#   972B12  アドバンス・オーストラリア・フェア / オーストラリア連邦国歌  alias Advance Australia Fair, reading
#           あとはんすおす (truncated), tie-up 国歌アニメ<番組名>, theme 国歌, genre ポップス
#   100A1   Love / Somebody
#   100A2   Other Song / Love Band
#   100A3   abc / Somebody (genre なし)
#   409B6   残酷な天使のテーゼ / Somebody  reading さんこくなてん (truncated), genre アニメ, content type DAM良音
#   3A1     今夜はひとりかい? / Somebody  alias Are You Lonesome Tonight? (no j_song_kana)
#   590B42  *〜アスタリスク〜 / オレンジレンジ  no English name in Pasela
#   C1      COLORS!! / Tester,  C2 Colors of the Wind / Tester (番組V),  C3 Innocent Colors / Tester
# Pasela's singer search tables also contain the tie-up (国歌アニメ, こつかあにめ) attached to
# unrelated singers (Somebody, Tester), as in the real data.
RSpec.describe 'POST /api/v1/command/search', :no_db_transaction, type: :request do
  it 'finds Advance Australia Fair by its English name (S5 acceptance)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'advance australia' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['972B12'])
  end

  it 'finds songs by their English alias (S5)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'lonesome tonight' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['3A1'])
  end

  it 'finds a katakana title by a kana query with ー and dakuten (S6)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'あどばんすおーすとらりあ' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['972B12'])
  end

  it 'finds a kanji title by a kana query longer than its truncated reading (S6)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'ざんこくなてんしのてーぜ' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['409B6'])
  end

  it 'finds katakana words that contain ー in the middle of a title (S6)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'オーストラリア' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['972B12'])
  end

  it 'ignores ・ and spaces, so a title can be typed with or without them' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = ['アドバンスオーストラリアフェア', 'アドバンス・オーストラリア・フェア', 'アドバンス オーストラリア'].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['972B12']))
  end

  it 'folds half-width and full-width characters' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[ｱﾄﾞﾊﾞﾝｽ ＡＤＶＡＮＣＥ].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['972B12']))
  end

  it 'finds songs and singers by English names from the dictionary, matched on the normalised name' do
    # The dictionary writes ~ where Pasela writes 〜.
    dictionary = { '*~アスタリスク~' => ['Asterisk'], 'オレンジレンジ' => ['ORANGE RANGE'] }
    TbldumpImportService.new.call(
      'spec/fixtures/tbldump/search', workers: 2, dictionary: dictionary, logger: Logger.new(nil)
    )
    codes = ['asterisk', 'asterisk orange range'].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['590B42']))
  end

  it 'ignores the tie-up rows Pasela mixes into its singer search tables' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[国歌アニメ こつかあにめ].map do |str|
      post '/api/v1/command/search', params: { str: str, constraint: 'artist' }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq([]))
  end

  it 'finds songs by singer alias and by tie-up' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = ['national anthem', '国歌アニメ'].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['972B12']))
  end

  it 'requires every word to match' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = ['advance anthem', 'advance nomatch'].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to eq([['972B12'], []])
  end

  it 'ranks exact titles first, then titles starting with the query, then titles containing it' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'COLORS' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(%w[C1 C2 C3])
  end

  it 'ranks song-name matches before singer-name matches' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'love' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(%w[100A1 100A2])
  end

  it 'does not let short readings match every query that starts with them' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'らふらふらふ' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq([])
  end

  it 'treats % and _ as ordinary characters, not wildcards' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[a_c %].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq([]))
  end

  it '番組V is a filter, not a search word, in any case or width, even glued to other text' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = ['colors 番組V', 'colors 番組v', 'colors 番組Ｖ', 'colors番組V', '番組V colors'].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['C2']))
  end

  it '番組V on its own lists every 番組V song, under any constraint' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[all title artist tags].map do |constraint|
      post '/api/v1/command/search', params: { str: '番組V', constraint: constraint }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to all(eq(['C2']))
  end

  it '番組V combines with the constraint' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = ['colors 番組V', 'tester 番組V'].map do |str|
      post '/api/v1/command/search', params: { str: str, constraint: 'artist' }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to eq([[], ['C2']])
  end

  it '番組V songs get 【番組V】 after the name, and extra.song_name stays the raw title' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'colors' }

    expect(response.parsed_body['results'].first.map { |r| [r['song'], r['extra']['song_name']] }).to eq(
      [['COLORS!!', 'COLORS!!'],
       ['Colors of the Wind【番組V】', 'Colors of the Wind'],
       ['Innocent Colors', 'Innocent Colors']]
    )
  end

  it 'constraint title only matches song names and readings' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'love', constraint: 'title' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['100A1'])
  end

  it 'constraint artist only matches singer names and readings' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'love', constraint: 'artist' }

    expect(response.parsed_body['results'].first.pluck('code')).to eq(['100A2'])
  end

  it 'constraint tags matches genre, theme and content type, but not tie-ups, titles or the genre なし' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[アニメ 国歌 dam良音 なし love].map do |str|
      post '/api/v1/command/search', params: { str: str, constraint: 'tags' }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to eq([['409B6'], ['972B12'], ['409B6'], [], []])
  end

  it 'constraint all matches titles, artists and tie-ups, but not tags' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    codes = %w[アニメ dam良音 love].map do |str|
      post '/api/v1/command/search', params: { str: str }
      response.parsed_body['results'].first.pluck('code')
    end

    expect(codes).to eq([['972B12'], [], %w[100A1 100A2]])
  end

  it 'rejects an unknown constraint' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'love', constraint: 'genre' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'returns the content type in extra' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: '残酷な天使' }

    expect(response.parsed_body['results'].first.first['extra']).to include('content_type' => 'DAM良音')
  end

  it 'returns nothing for a blank query' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: '   ' }

    expect(response.parsed_body).to include('total' => 0, 'results' => [[]])
  end

  it 'returns the old result shape, with request_id' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'advance', page: 0, request_id: 'r1' }

    expect(response.parsed_body).to include(
      'search' => 'advance', 'page' => 0, 'total' => 1, 'request_id' => 'r1',
      'results' => [[a_hash_including('song' => 'アドバンス・オーストラリア・フェア', 'artist' => 'オーストラリア連邦国歌',
                                      'code' => '972B12')]]
    )
  end

  it 'returns the old newsong fields in extra, as strings, without nils' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    post '/api/v1/command/search', params: { str: 'advance' }

    expect(response.parsed_body['results'].first.first['extra']).to include(
      't_karaoke_master_id' => '1', 'genre_name' => 'ポップス', 'song_name_ruby' => 'あとはんすおす',
      'singer_name_ruby' => 'おすとらりあれんほうこつか', 'introcha' => "Australia's song let us",
      'tie_up' => '国歌アニメ<番組名>', 'tie_up_ruby' => 'こつかあにめ'
    ).and(satisfy { |h| h.values.all?(String) })
  end

  it 'pages through results (page size 1, straight on the service)' do
    TbldumpImportService.new.call('spec/fixtures/tbldump/search', workers: 2, logger: Logger.new(nil))
    pages = [0, 1].map do |page|
      result = SearchService.new.call('somebody', page, 1)
      [result[:total], result[:results].first.pluck(:code)]
    end

    expect(pages).to eq([[4, ['100A3']], [4, ['3A1']]])
  end
end
