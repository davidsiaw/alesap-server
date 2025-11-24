# in config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    user_origins = ENV['ALLOWED_ORIGINS'].split(',') || [
      'http://localhost:4000',
      'http://192.168.1.15:4000'
    ]

    origins *user_origins

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
