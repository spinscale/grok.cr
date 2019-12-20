require "./patterns"

class Grok

  @@global_pattern_definitions : Hash(String, String)
  @@global_pattern_definitions = GrokPatterns.patterns


  @patterns : Array(Regex)

  def initialize(text_patterns : Array(String),
                 pattern_definitions = {} of String => String)
    all_pattern_definitions = pattern_definitions.merge @@global_pattern_definitions
    resolved_pattern_definitions = all_pattern_definitions.select do |name, pattern|
      pattern.index("%{").nil?
    end
    unresolved_pattern_definitions = all_pattern_definitions.select do |name, pattern|
      !pattern.index("%{").nil?
    end
    i = 0
    # this is rather brute force but gets the job done for now...
    # this should be solved in a better way in the future
    while i < 1024
      resolved_patterns_count = resolved_pattern_definitions.size
      unresolved_pattern_definitions.each do |name, pattern|
        begin
          converted_string = Grok.convert_to_regex_string pattern, resolved_pattern_definitions
          if converted_string.index("%{").nil?
            resolved_pattern_definitions[name] = converted_string
          end
        rescue
        end
      end

      unresolved_pattern_definitions.reject! resolved_pattern_definitions.keys

      # exit early if there is no change compared to the last run
      # or no more patterns to resolve
      if unresolved_pattern_definitions.empty? || resolved_patterns_count == resolved_pattern_definitions.size
        break
      end

      i = i + 1
    end

    if !unresolved_pattern_definitions.empty?
      raise "could not resolve the following patterns #{unresolved_pattern_definitions}, please make sure there are no recursing or deep pattern definitions"
    end

    @patterns = text_patterns.map do |p|
      converted_string = Grok.convert_to_regex_string p, resolved_pattern_definitions
      Regex.new converted_string
    end

  end

  # converts a grok string to a regex based string
  # may need to be called recursively if a pattern contains a nested sub pattern
  def self.convert_to_regex_string (input : String, pattern_definitions : Hash(String, String))
    # check for regex pattern
    len = input.size
    # replace regex pattern
    # todo map position of pattern with match data
    # todo return regexdata
    start = input.index("%{")
    if start.nil?
      raise "no grok pattern found"
    end

    idx = start
    output = String::Builder.new(input.size)
    output << input[0, start]
    while !idx.nil? && idx < len
      # extract name and pattern definition
      end_index = input.index("}", idx)

      if end_index.nil?
        raise "unclosed grok pattern starting at position #{idx}"
      end

      beginning = idx + 2
      # sth like GREEDYDATA:foo without the {}
      data = input[beginning, end_index-beginning]
      if data.index(":").nil?
        output << pattern_definitions[data]
      else
        regex_name, named_capture = data.split(":", 2)
        output << "(?<"
        output << named_capture
        output << ">"
        output << pattern_definitions[regex_name]
        output << ")"
      end

      # on to the next regex
      idx = input.index("%{", end_index)

      # no more matches, make sure we append the remaining text
      # if there is any
      if idx.nil? && end_index+1 < len
        output << input[end_index+1]
      elsif !idx.nil? && end_index < idx
        output << input[end_index+1, idx-end_index-1]
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
    return {} of String => String
  end
end
