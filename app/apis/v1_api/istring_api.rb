# frozen_string_literal: true

# GET istring
class IstringApi < Grape::API
  resource :istring do

    desc 'GET istring'
    params do
      requires :id, type: String, desc: 'Istring ID.'
    end
    get ':id' do
      obj = Istring.find(params[:id])

      { result: obj }

    rescue ActiveRecord::RecordNotFound
      status 404
      { error: :not_found }
    end

    desc 'GET istring listing'
    params do
      optional :page, type: Integer, default: 1, desc: 'Page number'
      optional :limit, type: Integer, default: 20, desc: 'Number of istrings returned per page'
    end
    get do
      limit = params[:limit]
      if limit > 100
        limit = 100
      end
      if limit < 0
        limit = 1
      end
      query = Istring
      res = query.offset(params[:page] - 1).limit(limit)

      count = Istring.count
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

    desc 'PUT istring'
    params do
      # str string
      requires :str, type: String, desc: 'Istring str'

    end
    put do
      obj = Istring.find_or_initialize_by(params)
      obj.save!
      { result: obj }
    end

  end
end
