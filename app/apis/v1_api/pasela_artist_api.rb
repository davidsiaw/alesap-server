# frozen_string_literal: true

# GET pasela_artist
class PaselaArtistApi < Grape::API
  resource :pasela_artist do

    desc 'GET pasela_artist'
    params do
      requires :id, type: String, desc: 'PaselaArtist ID.'
    end
    get ':id' do
      obj = PaselaArtist.find(params[:id])

      { result: obj }

    rescue ActiveRecord::RecordNotFound
      status 404
      { error: :not_found }
    end

    desc 'GET pasela_artist listing'
    params do
      optional :page, type: Integer, default: 1, desc: 'Page number'
      optional :limit, type: Integer, default: 20, desc: 'Number of pasela_esong_artists returned per page'
    end
    get do
      limit = params[:limit]
      if limit > 100
        limit = 100
      end
      if limit < 0
        limit = 1
      end
      query = PaselaArtist
      res = query.offset(params[:page] - 1).limit(limit)

      count = PaselaArtist.count
      fullpages = count / limit
      lastpage = count % limit ? 1 : 0

      {
        count: count,
        maxpage: fullpages+lastpage,
        page: params[:page],
        limit: limit,
        result: res
      }
    end


    desc 'PUT pasela_artist'
    params do
      # master singer id
      requires :master_singer_id, type: String, desc: 'ID of a PaselaEsong'

      # artist_name userdef_istring
      requires :artist_name_id, type: String, desc: 'ID of a Istring'

    end
    put do
      obj = PaselaArtist.find_or_initialize_by(params)
      obj.save!
      { result: obj }
    end




  end
end
