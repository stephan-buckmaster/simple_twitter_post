require File.dirname(__FILE__) + '/test_helper.rb' 

class SimpleTwitterPostBaseTest < Test::Unit::TestCase

  def setup
    HTTPClient.reset_last_fields
  end

  def test_simple_message
    a = SimpleTwitterPost::Base.new
    response = a.post('testing')

    assert_equal ["https://api.twitter.com/1/statuses/update.json"], HTTPClient.last_urls
    assert_equal [{:status=>"testing"}], HTTPClient.last_messages

    assert_equal "[Post to https://api.twitter.com/1/statuses/update.json: {:status=>\"testing\"}]", response.content
  end

  def test_message_with_url
    a = SimpleTwitterPost::Base.new
    response = a.post('testing :url', :url => 'http://mysite.com/article/2')
    
    # Tinyurl is used to shorten the URL
    assert_equal ["http://tinyurl.com/api-create.php", "https://api.twitter.com/1/statuses/update.json"], HTTPClient.last_urls
    assert_equal [{:url=>"http://mysite.com/article/2"},
                  {:status=> "testing [Post to http://tinyurl.com/api-create.php: {:url=>\"http://mysite.com/article/2\"}]"}], HTTPClient.last_messages

    assert_equal "[Post to https://api.twitter.com/1/statuses/update.json: {:status=>\"testing [Post to http://tinyurl.com/api-create.php: {:url=>\\\"http://mysite.com/article/2\\\"}]\"}]", response.content
  end

  def test_message_truncated
    a = SimpleTwitterPost::Base.new
    response = a.post('a' * 140)
    assert_equal "[Post to https://api.twitter.com/1/statuses/update.json: {:status=>\"#{'a'*140}\"}]", response.content

    response = a.post('b' * 141)
    assert_equal "[Post to https://api.twitter.com/1/statuses/update.json: {:status=>\"#{'b'*140}\"}]", response.content
  end

  def test_empty_message
    a = SimpleTwitterPost::Base.new
    response = a.post('')
    assert_equal "[Post to https://api.twitter.com/1/statuses/update.json: {:status=>\"\"}]", response.content
  end

  def test_nil_message
    a = SimpleTwitterPost::Base.new
    assert_raises ArgumentError do
      response = a.post(nil)
    end
  end
end
