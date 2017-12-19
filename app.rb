require 'sinatra/base'
require 'erb'
require 'adafruit/io'
require 'json'

#
# If using Heroku, set using
#   $ heroku config:add IO_USERNAME=username
#   $ heroku config:add IO_KEY=key
#
# If in development, set from command line
#   $ bundle exec thin start IO_USERNAME=username IO_KEY=key
#
$io_client = Adafruit::IO::Client.new username: ENV['IO_USERNAME'], key: ENV['IO_KEY']

class AdafruitApp < Sinatra::Base
  set :session, true
  set :erb, {:format => :html5 }
  set :root, File.dirname(__FILE__)
  set :public_folder, Proc.new { File.join(root, "public") }

  get '/' do
    erb :index
  end

  get '/check' do
    content_type :json

    feeds = params[:feeds]
    if feeds && feeds.size > 0
      data = {}
      keys = feeds.split(',')
      keys.each do |k|
        # get most recent data point for the given feed
        response = $io_client.data(k, limit: 1)

        if response
          data[k] = response[0]
        else
          data[k] = nil
        end
      end
      data.to_json
    end
  end

  post '/update' do
    content_type :json

    feed_key = params[:key]
    value = params[:value]

    if !(feed_key && value) || (feed_key.empty? || value.empty?)
      return { error: 'feed_key and value must not be blank!' }.to_json
    end

    $io_client.send_data(feed_key, value).to_json
  end
end
