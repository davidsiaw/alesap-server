# frozen_string_literal: true

require 'rails_helper'

# Unauthenticated endpoints that no frontend uses. The import trigger was replaced by
# `rake pasela:import`; the CRUD APIs could create records without authentication.
RSpec.describe 'Removed endpoints', type: :request do
  [
    [:post, '/api/v1/command', { verb: 'loadsongs', subject: '1', amount: 1 }],
    [:get, '/api/v1/istring', {}],
    [:put, '/api/v1/istring', { str: 'x' }],
    [:get, '/api/v1/pasela_esong', {}],
    [:put, '/api/v1/pasela_esong', { esong_key: 'x', name_id: 'x', ruby_id: 'x' }],
    [:get, '/api/v1/pasela_artist', {}],
    [:put, '/api/v1/pasela_artist', { master_singer_id: 'x', artist_name_id: 'x' }],
    [:get, '/api/v1/pasela_esong_pasela_artist', {}],
    [:put, '/api/v1/pasela_esong_pasela_artist', { song_id: 'x', artist_id: 'x' }]
  ].each do |verb, path, params|
    it "#{verb.upcase} #{path} is gone" do
      send(verb, path, params: params)

      expect(response).to have_http_status(:not_found)
    end
  end

  it 'still serves the health check' do
    get '/api/v1/health'

    expect(response).to have_http_status(:ok)
  end
end
