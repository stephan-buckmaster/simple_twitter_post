require 'rubygems'
require 'active_support'
require 'test/unit'
# require 'mocha'

RAILS_ROOT = File.dirname(__FILE__) unless defined?(RAILS_ROOT)

# if RAILS_ENV=='test' then SimpleTwitterPost::Base#post does nothing
RAILS_ENV = 'plugin_test' unless defined?(RAILS_ENV)

# Some simple stubbing
module Spawn
  def spawn
    yield
  end
end

require File.join(File.dirname(__FILE__), '..', 'lib', 'simple_twitter_post')

# Some more involved stubbing.
# TODO Use mocha instead!

class Grackle::Statuses
 
  attr_reader :status
  def update!(options)
    @status = options
  end
end
class Grackle::Client

  attr_reader :statuses
  def initialize(*args)
    @statuses = Grackle::Statuses.new
  end

end

class HTTPClient
  def self.last_urls
    @last_urls
  end

  def self.last_messages
    @last_messages
  end

  def self.reset_last_fields
    @last_urls = []
    @last_messages = []
  end
  
  def post(url, message)
    self.class.last_urls << url
    self.class.last_messages << message
    Struct.new(:content,:header).new("[Post to #{url}: #{message.inspect}]", Struct.new(:status_code).new(200))
  end
end
