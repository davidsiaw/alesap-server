# frozen_string_literal: true

# GET command
class CommandApi < Grape::API

  # Command list
  STOP_SONG_COMMAND = 2

  resource :command do

    desc 'GET command'
    params do
      requires :id, type: String, desc: 'Command ID.'
    end
    get ':id' do
      obj = Command.find(params[:id])

      { result: obj }

    rescue ActiveRecord::RecordNotFound
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


    desc 'POST command'
    params do
      # verb string
      requires :verb, type: String, desc: 'Command verb'

      # subject string
      requires :subject, type: String, desc: 'Command subject'

      # amount integer
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



  end
end
