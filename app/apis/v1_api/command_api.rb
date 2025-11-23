# frozen_string_literal: true

# GET command
class CommandApi < Grape::API
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
      end
      post do

        strs = Istring.where("str LIKE ?", "#{params[:str]}%")

        songs = PaselaEsong.joins(:name).merge(strs)
        artists = PaselaArtist.joins(:artist_name).merge(strs)

        res = PaselaEsongPaselaArtist.
          joins(:song, :artist).
          merge(songs).
          limit(20).
          map do |x|
            {
              song: x.song_name,
              code: x.code,
              artist: x.artist_name
            }
          end

        p res

        {
          search: params['str'],
          results: [
            res
          ]
        }
      end

    end



  end
end
