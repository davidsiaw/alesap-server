# frozen_string_literal: true

# GET pasela_esong
class PaselaEsongApi < Grape::API
  resource :pasela_esong do

    desc 'GET pasela_esong'
    params do
      requires :id, type: String, desc: 'PaselaEsong ID.'
    end
    get ':id' do
      obj = PaselaEsong.find(params[:id])

      { result: obj }

    rescue ActiveRecord::RecordNotFound
      status 404
      { error: :not_found }
    end

    desc 'GET pasela_esong listing'
    params do
      optional :page, type: Integer, default: 1, desc: 'Page number'
      optional :limit, type: Integer, default: 20, desc: 'Number of pasela_esongs returned per page'
    end
    get do
      limit = params[:limit]
      if limit > 100
        limit = 100
      end
      if limit < 0
        limit = 1
      end
      query = PaselaEsong
      res = query.offset(params[:page] - 1).limit(limit)

      count = PaselaEsong.count
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


    desc 'PUT pasela_esong'
    params do
      # esong_key string
      requires :esong_key, type: String, desc: 'PaselaEsong esong_key'

      # name userdef_istring
      requires :name_id, type: String, desc: 'ID of a Istring'

      # ruby userdef_istring
      requires :ruby_id, type: String, desc: 'ID of a Istring'

    end
    put do
      obj = PaselaEsong.find_or_initialize_by(params)
      obj.save!
      { result: obj }
    end




  end
end
