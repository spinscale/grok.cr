require "./patterns"

class Grok

  @@global_pattern_definitions : Hash(String, String)
  @@global_pattern_definitions = GrokPatterns.patterns

  @patterns : Array(Regex)

  def initialize(patterns_as_string : Array(String),
    custom_pattern_definitions = {} of String => String)
    pattern_definitions = custom_pattern_definitions.merge @@global_pattern_definitions
    @patterns = patterns_as_string.map do |pattern|
      Regex.new Grok.convert_recursively(pattern, pattern_definitions)
    end    
  end

  def self.convert_recursively(pattern : String, pattern_definitions : Hash(String, String), found_patterns = Array(String).new())
    len = pattern.size
    start = pattern.index("%{")
    if start.nil?
      if found_patterns.empty?
        raise "no grok pattern found"
      else
        return pattern
      end
    end

    idx = start
    output = String::Builder.new
    output << pattern[0, start]
    while !idx.nil? && idx < len
      # extract name and pattern definition
      end_index = pattern.index("}", idx)

      if end_index.nil?
        raise "unclosed grok pattern starting at position #{idx}"
      end

      # remove {} from string
      beginning = idx + 2
      data = pattern[beginning, end_index-beginning]
      # prevent recursion
      if found_patterns.includes?(data) 
        raise "pattern #{pattern} is defined recursive"
      end

      # only a pattern we need to resolve
      if data.index(":").nil?
        pattern_name = data
        if pattern_definitions.has_key?(pattern_name)
          output << Grok.convert_recursively pattern_definitions[data], pattern_definitions, found_patterns + [data]
        else
        end
      else
        regex_name, named_capture = data.split(":", 2)
        output << "(?<"
        output << named_capture
        output << ">"
        output << Grok.convert_recursively pattern_definitions[regex_name], pattern_definitions, found_patterns + [named_capture]
        output << ")"
      end

      # on to the next regex
      idx = pattern.index("%{", end_index)

      # no more matches, make sure we append the remaining text
      # if there is any
      if idx.nil? && end_index+1 < len
        output << pattern[end_index+1, len]
      elsif !idx.nil? && end_index < idx
        output << pattern[end_index+1, idx-end_index-1]
      end
    end

    output.to_s
  end

  def parse(content : String)
    @patterns.each do |pattern|
      match = content.match pattern
      if !match.nil?
        return match.named_captures
      end
    end
    # no matches empty hash map
    {} of String => String
  end
end