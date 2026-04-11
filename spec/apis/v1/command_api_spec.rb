# frozen_string_literal: true

RSpec.describe CommandApi, type: :request do
  # intercept web requests
  before do
    WebMock.enable!
  end

  after do
    WebMock.disable!
  end

  describe "/queue" do
    it 'performs a queue' do
      stub = stub_request(:post, "http://order.mashup.jp/bridge/post_request.php")
        .with(body: "akey=1&ecd=4&scd=3&skey=2")
        .to_return(body: "lol")

      post '/api/v1/command/queue', params: {
        akey: 1,
        skey: 2,
        scd: 3,
        ecd: 4
      }

      expect(response.body).to eq({ result: 'ok' }.to_json)
      expect(stub).to have_been_requested
    end
  end

  describe "/stop" do
    it 'tries to stop the song' do
      stub = stub_request(:post, "http://order.mashup.jp/bridge/post_request.php")
        .with(body: "akey=1&scd=3&skey=2&type=2")
        .to_return(body: "lol")

      post '/api/v1/command/stop', params: {
        akey: 1,
        skey: 2,
        scd: 3
      }

      expect(response.body).to eq({ result: 'ok' }.to_json)
      expect(stub).to have_been_requested
    end
  end

end
