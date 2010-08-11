require 'httpclient'
require 'grackle'

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

    # :logger => instance of some logger class
    # assuming logger can do logger.error
    def initialize(options = {})
      @logger = options[:logger]
    end

    def config
      return @config unless @config.blank?
  
      @config = YAML::load(ERB.new(IO.read(File.join(RAILS_ROOT, 'config', 'simple_twitter_post.yml'))).result)[RAILS_ENV]
      @config = HashWithIndifferentAccess.new(@config)
    end
  
    def grackle_client
      return @grackle_client unless @grackle_client.blank?
      # HashWithIndifferentAccess is not good enough for "merge"
      @grackle_client =  Grackle::Client.new(:auth=> {:type=>:oauth,
                                                      :consumer_key => config[:consumer_key],
                                                      :consumer_secret => config[:consumer_secret],
                                                      :token => config[:token],
                                                      :token_secret => config[:token_secret]})
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
        begin
          unless shortener.url.nil?
            # Replace the URL by a tinyurl (until this is made configurable)
            # TODO : check return value
            tinyurl_response = self.tinyurl_http_client.post("http://tinyurl.com/api-create.php", :url => shortener.url)
            if tinyurl_response.header.status_code  == 200 
              shortener.url = tinyurl_response.content 
            else
              shortener.url = 'URL unavailable'
              log_error { "#{self.class}: tinyurl problem / #{tinyurl_response.inspect}" }
            end
          end

          begin
            result = self.grackle_client.statuses.update! :status => shortener.shortened
            log_info { "Udated twitter status http://twitter.com/#{result.user.screen_name}/statuses/#{result.id}" }
            result
          rescue Grackle::TwitterError => e
            log_error { "Grackle::TwitterError #{e} while updating twitter status for #{args.inspect}" }
          end
        rescue Exception => e
          log_error { "#{self.class}: Exception #{e} while updating twitter status for #{args.inspect}" }
        end
      end
    end

    protected
    # Using yield to avoid evaluating when there is no logger
    def log_error(&block)
      return if @logger.nil?
      @logger.error(yield)
    end

    def log_info
      return if @logger.nil?
      @logger.info(yield)
    end
  end
end
