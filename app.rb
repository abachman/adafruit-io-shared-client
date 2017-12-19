require 'sinatra/base'
require 'erb'
require 'adafruit/io'
require 'json'
require 'memcachier'
require 'dalli'

# caching / rate limiting support
ENV["MEMCACHE_SERVERS"] = ENV["MEMCACHIER_SERVERS"]
ENV["MEMCACHE_USERNAME"] = ENV["MEMCACHIER_USERNAME"]
ENV["MEMCACHE_PASSWORD"] = ENV["MEMCACHIER_PASSWORD"]

#
# If using Heroku, set using
#   $ heroku config:add IO_USERNAME=username
#   $ heroku config:add IO_KEY=key
#
# If in development, set from command line
#   $ bundle exec thin start IO_USERNAME=username IO_KEY=key
#
$io_client = Adafruit::IO::Client.new username: ENV['IO_USERNAME'], key: ENV['IO_KEY']
if ENV['IO_URL']
  $io_client.api_endpoint = ENV['IO_URL']
end

class AdafruitApp < Sinatra::Base
  set :session, true
  set :erb, {:format => :html5 }
  set :root, File.dirname(__FILE__)
  set :public_folder, Proc.new { File.join(root, "public") }

  set :cache, Dalli::Client.new

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
        response = settings.cache.fetch("feed:#{k}") do
          resp = $io_client.data(k, limit: 1)
          settings.cache.set("feed:#{k}", resp, 10) # cache for 10 seconds
          resp
        end

        if response
          data[k] = response[0]
        else
          data[k] = nil
        end

      end

      # response
      data.to_json
    else
      {}
    end
  end

  post '/update' do
    content_type :json

    # limit to 1 update globally every 15 seconds
    success = false

    allow_after = settings.cache.fetch("allow-feed-update") do
      feed_key = params[:key]
      value = params[:value]

      if !(feed_key && value) || (feed_key.empty? || value.empty?)
        return { error: 'feed_key and value must not be blank!' }.to_json
      end

      $io_client.send_data(feed_key, value)

      success = true

      in_15_seconds = Time.now.to_i + 15
      settings.cache.set("allow-feed-update", in_15_seconds, 15)
      in_15_seconds
    end

    {
      success: success,
      wait: allow_after - Time.now.to_i
    }.to_json
  end
end
