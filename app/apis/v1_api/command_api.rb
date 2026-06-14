# frozen_string_literal: true

# GET command
class CommandApi < Grape::API

  # Command list
  STOP_SONG_COMMAND = 2

  resource :command do

    desc 'POST command'
    params do
      requires :verb, type: String, desc: 'Command verb'
      requires :subject, type: String, desc: 'Command subject'
      requires :amount, type: Integer, desc: 'Command amount'
    end
    post do
      obj = Command.create!(params)

      CommandCreateTriggerJob.perform_later(obj.id)

      { result: obj }
    end


    resource :search do

      desc 'search for songs'
      params do
        optional :str, type: String, desc: 'search str'
        optional :page, type: Integer, desc: 'page num'
        optional :request_id, type: String, desc: 'requestid'
      end
      post do

        ss = SearchService.new(params[:str], params[:page].to_i)

        ss.result.merge(request_id: params[:request_id])

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

    desc 'import favourites'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
    end
    get 'import_favourites/?' do
      favourites = UserFavourite.where(nickname: params[:nickname])
      hash = favourites.each_with_object({}) { |f, h| h[f.song_code] = true }
      cache = SongCacheService.build(favourites.pluck(:song_code))
      { favourites: hash, cache: cache }
    end

    desc 'export favourites'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
      requires :data, type: Hash, desc: 'Favourites hash { song_code: true }'
    end
    post 'export_favourites/?' do
      codes = params[:data].keys
      unless codes.all? { |c| c.is_a?(String) && c.present? && c.length <= 20 }
        status 422
        return { error: :invalid_data }
      end

      UserFavourite.where(nickname: params[:nickname]).delete_all
      now = Time.current
      rows = codes.map { |code| { nickname: params[:nickname], song_code: code, updated_at: now } }
      UserFavourite.insert_all(rows) if rows.any?
      { result: :ok }
    end

    desc 'import history'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
    end
    get 'import_history/?' do
      history = SongHistory.where(nickname: params[:nickname])
        .order(:updated_at)
        .map do |h|
          {
            song_code: h.song_code,
            last_played_date: h.last_played_date,
            last_played_time: h.last_played_time
          }
        end
      cache = SongCacheService.build(history.map { |h| h[:song_code] })
      { song_history: history, cache: cache }
    end

    desc 'export history'
    params do
      requires :nickname, type: String, desc: 'Anonymous user key'
      requires :data, type: Array, desc: 'Array of history entries'
    end
    post 'export_history/?' do
      entries = params[:data]
      unless entries.all? { |e| e.is_a?(Hash) && (e['song_code'] || e[:song_code]).is_a?(String) && (e['song_code'] || e[:song_code]).present? && (e['song_code'] || e[:song_code]).length <= 20 }
        status 422
        return { error: :invalid_data }
      end

      SongHistory.where(nickname: params[:nickname]).delete_all
      now = Time.current
      rows = entries.map do |entry|
        {
          nickname: params[:nickname],
          song_code: entry['song_code'] || entry[:song_code],
          last_played_date: entry['last_played_date'] || entry[:last_played_date],
          last_played_time: entry['last_played_time'] || entry[:last_played_time],
          updated_at: now
        }
      end
      SongHistory.insert_all(rows) if rows.any?
      { result: :ok }
    end

    desc 'GET command'
    params do
      requires :id, type: String, desc: 'Command ID.'
    end
    get ':id' do
      obj = Command.find(params[:id])

      { result: obj }

    rescue ActiveRecord::RecordNotFound, ArgumentError
      status 404
      { error: :not_found }
    end

    desc 'GET command listing'
    params do
      optional :page, type: Integer, default: 1, desc: 'Page number'
      optional :limit, type: Integer, default: 20, desc: 'Number of commands returned per page'
    end
    get do
      query = Command
      res = query.offset(params[:page] - 1).limit(params[:per_page])

      { result: res }
    end

  end
end
