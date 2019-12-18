class Grok

  @@global_pattern_definitions = {
    "GREEDYDATA" => ".*",
    "INT" => "(?:[+-]?(?:[0-9]+))"
  }

  @patterns : Array(Regex)

  def initialize(text_patterns : Array(String), @pattern_defitions = Array(String).new)
    @patterns = text_patterns.map do |p|
      # check for regex pattern
      len = p.size
      # replace regex pattern
      # todo map position of pattern with match data
      # todo return regexdata
      start = p.index("%{")
      if start.nil?
        raise "no grok pattern found"
      end

      idx = start
      converted_string = String::Builder.new(p.size)
      converted_string << p[0, start]
      while !idx.nil? && idx < len
        # extract name and pattern definition
        end_index = p.index("}", idx)

        if end_index.nil?
          raise "unclosed grok pattern starting at position #{idx}"
        end

        beginning = idx + 2
        # sth like GREEDYDATA:foo without the {}
        data = p[beginning, end_index-beginning]
        if data.index(":").nil?
          raise "missing identifier after colon at position #{idx}"
        end
        regex_name, named_capture = data.split(":", 2)

        converted_string << "(?<"
        converted_string << named_capture
        converted_string << ">"
        converted_string << @@global_pattern_definitions[regex_name]
        converted_string << ")"

        # on to the next regex
        idx = p.index("%{", end_index)

        # no more matches, make sure we append the remaining text
        # if there is any
        if idx.nil? && end_index+1 < len
          converted_string << p[end_index+1]
        end
      end

      Regex.new converted_string.to_s
    end
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
