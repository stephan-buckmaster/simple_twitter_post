module SimpleTwitterPost

  class OperationNotSupportedError < RuntimeError; end

  class StringShortener

  TWEET_LIMIT = 140 unless defined?(TWEET_LIMIT)

  # Treating a :url option as special: It should not be shortened
  def initialize(*args)
    raise ArgumentError.new('nil not allowed') if args.nil?
    args << {} if args.length == 1
    
    case args
    when String
      @string = args
      @options = {}
    when Array
      @string, @options = args
      raise ArgumentError.new('Expected String as first argument') unless @string.is_a?(String)
      raise ArgumentError.new('Expected Hash as last argument') unless @options.is_a?(Hash)
    else
      raise ArgumentError.new('Expected String or [String, Hash]')
    end
  end

  def url
    @options[:url]
  end

  def url=(v)
    @options[:url]=v
  end

  def fully_expanded
    symbol_regexp = /(:[a-z]\w*)/i
    @string.gsub(symbol_regexp) do |var|
      var = var.sub /^:/,''
      value = @options[var.to_sym]
    end
  end

  def shortened
    return @string[0, TWEET_LIMIT] if @options == {}
    # Find length of named bind variables
    symbol_regexp = /(:[a-z]\w*)/i
    named_bind_variables =  @string.scan(symbol_regexp).collect { |match| match.first}
    named_bind_variables_length =  named_bind_variables.inject(0) { |s,a| s+a.length}
    length_without_subs = @string.length - named_bind_variables_length

    # How many :url to substitute?
    url_count = named_bind_variables.select { |var| var == ':url'}.length

    # How many non-:url to substitute?
    non_url_named_bind_variables = named_bind_variables.select { |var| var != ':url'}
    
    # You would expect this to be 0 or 1 most of the time
    url_length = self.url.nil? ? 0 : self.url.length

    # Now we have
    free_space = TWEET_LIMIT - length_without_subs - url_count*url_length

    # If free space is less than 4 characters per non-:url bind variable, 
    # shorten the simple way (fully_expanded, then truncated to TWEET_LIMIT)
    # 
    # The 4 comes from replacing :abc=>"Abcdef" by "Ab.." so that at least the 
    # first two letters show up (yes so a 1,2,3 or 4-letter value would stay the same)
    required_space = non_url_named_bind_variables.inject(0) do |s, var|
       var = var.sub /^:/,''
       value = @options[var.to_sym]
       s + [4,value.length].min
    end

    if free_space < required_space
      return fully_expanded[0, TWEET_LIMIT]
    end

    # Now distribute the free space over the substitutions.
    values_needing_shortening = non_url_named_bind_variables.select do |var|
       var = var.sub /^:/,''
      @options[var.to_sym].length > 4
    end

    values_not_needing_shortening = non_url_named_bind_variables.select do |var|
       var = var.sub /^:/,''
      @options[var.to_sym].length <= 4
    end

    # So we can subtract values_not_needing_shortening from the free space, and
    # divide the rest amongst the others

    length_for_values_not_needing_shortening = values_not_needing_shortening.inject(0) {|s,v| s+v.length}
    if values_needing_shortening.length > 0
      length_per_long_substitution = (free_space - length_for_values_not_needing_shortening) / values_needing_shortening.length
    else
      length_per_long_substitution = 0
    end

    # Now we can do our substitution. We have 3 cases
    # 1. :url
    # 2. :abc where @options[:abc] is longer than 4
    # 3. :abc where @options[:abc] is not longer than 4

    @string.gsub(symbol_regexp) do |match|
      match = match.sub(/^:/,'').to_sym
      raise "Missing value for #{match}" if @options[match].nil?
 
      if match == :url
        @options[:url] # no need to shorten, since we calculated with full length
      else
        value = @options[match]
        if value.length <= 4
          value
        else
          if value.length <= length_per_long_substitution
            value
          else
            value[0,length_per_long_substitution-2] + '..'
          end
        end
      end
    end[0,TWEET_LIMIT]
  end

end
end
