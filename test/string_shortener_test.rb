require File.dirname(__FILE__) + '/test_helper.rb' 

class StringShortenerTest < Test::Unit::TestCase

  def test_simple_message
    a = SimpleTwitterPost::StringShortener.new('a')
    assert_equal 'a', a.shortened
  end

  def test_simple_message_with_colon
    a = SimpleTwitterPost::StringShortener.new('a:is a good letter')
    assert_equal 'a:is a good letter', a.shortened
  end

  def test_simple_message_with_repeated_subs
    a = SimpleTwitterPost::StringShortener.new(':a is a good letter. I really like the letter :a', :a => "A")
    assert_equal "A is a good letter. I really like the letter A", a.shortened

    a = SimpleTwitterPost::StringShortener.new(':a is a letter. :b_letter is too. :a comes before :b_letter, though.', :a => "A", :b_letter => 'b')
    assert_equal "A is a letter. b is too. A comes before b, though.", a.shortened
  end

  def test_url_accessor
    a = SimpleTwitterPost::StringShortener.new('abcdef')
    assert_nil a.url

    a = SimpleTwitterPost::StringShortener.new('abcdef', :abc => 'abc')
    assert_nil a.url

    a = SimpleTwitterPost::StringShortener.new('abcdef', :url => 'test-url')
    assert_equal 'test-url', a.url

    a.url = 'other-url'
    assert_equal 'other-url', a.url
  end

  def test_README_example
    a = SimpleTwitterPost::StringShortener.new(":user has tagged posting ':title' with tags ':tags'. :url",
              :user => 'Haribald Kingston',
              :title => 'Fraunhofer FIT Touch-Free: Multi Users Gesture Control Technology',
              :tags => 'technology, touch-free, gesture, prototype',
              :url => 'http://tinyurl.com/2aeqpu')

    assert_equal "Haribald Kingston has tagged posting 'Fraunhofer FIT Touch-Fre..' with tags 'technology, touch-free, ..'. http://tinyurl.com/2aeqpu", a.shortened
  end

  def test_nil_arg
    assert_raises ArgumentError do
      SimpleTwitterPost::StringShortener.new(nil)
    end
  end

  def test_simple_url
    a = SimpleTwitterPost::StringShortener.new('more at :url', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal "more at http://tinyurl.com/2aeqpu7", a.shortened
  end

  def test_simple_url_long
    a = SimpleTwitterPost::StringShortener.new('x' * 104 + 'more at :url', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal ('x' * 104) + "more at http://tinyurl.com/2aeqpu7", a.shortened

    a = SimpleTwitterPost::StringShortener.new('x' * 106 + 'more at :url', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal ('x' * 106) + "more at http://tinyurl.com/2aeqpu7", a.shortened

    # Any longer and the URL is truncated
    a = SimpleTwitterPost::StringShortener.new('x' * 107 + 'more at :url', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal ('x' * 107) + "more at http://tinyurl.com/2aeqpu", a.shortened
    a = SimpleTwitterPost::StringShortener.new('x' * 108 + 'more at :url', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal ('x' * 108) + "more at http://tinyurl.com/2aeqp", a.shortened
  end

  def test_simple_message_with_substitution
    a = SimpleTwitterPost::StringShortener.new('a:is a good letter', :is => 'might be')
    assert_equal 'amight be a good letter', a.shortened
    a = SimpleTwitterPost::StringShortener.new('a :is a good letter', :is => 'might be')
    assert_equal 'a might be a good letter', a.shortened
  end

  def test_simple_message_with_several_substitutions
    a = SimpleTwitterPost::StringShortener.new('a:is a good letter, but b :rocks', :is => 'might be', :rocks => 'is much better')
    assert_equal 'amight be a good letter, but b is much better', a.shortened

    a = SimpleTwitterPost::StringShortener.new('a :is a :good letter', :is => 'might be', :good => 'wonderful')
    assert_equal 'a might be a wonderful letter', a.shortened
  end

  def test_long_message_with_substitution
    a = SimpleTwitterPost::StringShortener.new('a'*118 + ':is a good letter', :is => 'might be')
    assert_equal 'a' * 118 + 'might be a good letter', a.shortened

    a = SimpleTwitterPost::StringShortener.new('a'*119 + ':is a good letter', :is => 'might be')
    assert_equal 'a' * 119 + 'might.. a good letter', a.shortened
  end

  def test_long_message_with_substitution_and_url
    a = SimpleTwitterPost::StringShortener.new('a'*89 + ':is a good letter! :url', :is => 'really is', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal 'a' * 89 + 'really is a good letter! http://tinyurl.com/2aeqpu7', a.shortened

    # "really is" gets shortened but not the URL
    a = SimpleTwitterPost::StringShortener.new('a'*90 + ':is a good letter! :url', :is => 'really is', :url => 'http://tinyurl.com/2aeqpu7')
    assert_equal 'a' * 90 + 'really.. a good letter! http://tinyurl.com/2aeqpu7', a.shortened
  end

  def test_long_message_with_two_substitutions
    a = SimpleTwitterPost::StringShortener.new('a'*116 + ':is a :good letter', :is => 'might be', :good => 'good')
    assert_equal 'a' * 116 + 'might be a good letter', a.shortened

    a = SimpleTwitterPost::StringShortener.new('a'*116 + ':is a :good letter', :is => 'might be', :good => 'superior')
    assert_equal 'a' * 116 + 'might.. a super.. letter', a.shortened

    a = SimpleTwitterPost::StringShortener.new('a'*117 + ':is a :good letter', :is => 'might be', :good => 'ok')
    assert_equal 'a' * 117 + 'might be a ok letter', a.shortened

    a = SimpleTwitterPost::StringShortener.new('a'*118 + ':is a :good letter', :is => 'is', :good => 'fine')
    assert_equal 'a' * 118 + 'is a fine letter', a.shortened
  end
end
