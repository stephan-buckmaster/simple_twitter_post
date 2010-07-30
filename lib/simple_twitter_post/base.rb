require 'httpclient'
module SimpleTwitterPost

  class InvalidMessageError < StandardError
  end

  class Base

    # Want to wrap http-post calls asynchronous with spawn.
    # but if there is no spawn, use a simple fallback.
    if defined?(Spawn)
      include Spawn
    else
      def spawn
        yield
      end
    end

    def config
      return @config unless @config.blank?
  
      @config = YAML::load(ERB.new(IO.read(File.join(RAILS_ROOT, 'config', 'simple_twitter_post.yml'))).result)[RAILS_ENV]
      @config = HashWithIndifferentAccess.new(@config)
    end
  
    def twitter_http_client
      return @twitter_http_client unless @twitter_http_client.blank?
  
      @twitter_http_client = ::HTTPClient.new
      @twitter_http_client.connect_timeout = 50 # seconds; generous timeouts
      @twitter_http_client.receive_timeout = 50
      @twitter_http_client.set_auth('https://api.twitter.com', self.config[:user_id], self.config[:password])
      @twitter_http_client
    end
  
    def tinyurl_http_client
      return @tinyurl_http_client unless @tinyurl_http_client.blank?
  
      # tinyurl doesn't need any client authorization
      @tinyurl_http_client = ::HTTPClient.new
      @tinyurl_http_client.connect_timeout = 50 # seconds; generous timeouts
      @tinyurl_http_client.receive_timeout = 50
      @tinyurl_http_client
    end
  
    def post(*args)
      return if RAILS_ENV=='test'

      shortener = SimpleTwitterPost::StringShortener.new(*args)
      spawn do
        unless shortener.url.nil?
          # Replace the URL by a tinyurl (until this is made configurable)
          shortener.url = self.tinyurl_http_client.post("http://tinyurl.com/api-create.php", :url => shortener.url).content
        end
        self.twitter_http_client.post('https://api.twitter.com/1/statuses/update.json', :status => shortener.shortened)
      end
    end
  end
end
