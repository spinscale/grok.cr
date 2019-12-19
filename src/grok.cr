class Grok

  @@global_pattern_definitions = {
    "GREEDYDATA" => ".*",
    "INT" => "(?:[+-]?(?:[0-9]+))"
  }

  @patterns : Array(Regex)

  def initialize(text_patterns : Array(String),
                 pattern_definitions = {} of String => String)
    all_pattern_definitions = pattern_definitions.merge @@global_pattern_definitions
    @patterns = text_patterns.map do |p|
      converted_string = Grok.convert_to_regex_string p, all_pattern_definitions
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
        raise "missing identifier after colon at position #{idx}"
      end
      regex_name, named_capture = data.split(":", 2)

      output << "(?<"
      output << named_capture
      output << ">"
      output << pattern_definitions[regex_name]
      output << ")"

      # on to the next regex
      idx = input.index("%{", end_index)

      # no more matches, make sure we append the remaining text
      # if there is any
      if idx.nil? && end_index+1 < len
        output << input[end_index+1]
      end
    end

    output.to_s
  end

  # TODO repurpose into the text extraction to regex into own method
  # easier to test

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
