require "./patterns"

class Grok

  @@global_pattern_definitions : Hash(String, String)
  @@global_pattern_definitions = GrokPatterns.patterns

  @patterns : Array(Regex)

  def initialize(patterns_as_string : Array(String),
    custom_pattern_definitions = {} of String => String)
    pattern_definitions = custom_pattern_definitions.merge @@global_pattern_definitions
    @data_types = x = Array(Hash(String, String)).new(patterns_as_string.size) { Hash(String, String).new() }
    @patterns = patterns_as_string.map_with_index do |pattern, index|
      Regex.new convert_recursively(index, pattern, pattern_definitions)
    end    
  end

  def convert_recursively(index : Int32, pattern : String, pattern_definitions : Hash(String, String), found_patterns = Array(String).new())
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
        output << convert_recursively index, pattern_definitions[data], pattern_definitions, found_patterns + [data]
      else
        regex_name, named_capture = data.split(":", 2)
        if !named_capture.index(":").nil?
          named_capture, data_type = named_capture.split(":", 2)
          types = @data_types[index]
          types[named_capture] = data_type
        end
        output << "(?<"
        output << named_capture
        output << ">"
        output << convert_recursively index, pattern_definitions[regex_name], pattern_definitions, found_patterns + [named_capture]
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
    @patterns.each_with_index do |pattern, index|
      match = content.match pattern
      if !match.nil?
        if @data_types[index].empty?
          return match.named_captures
        else
          converted_captures = Hash(String, String | Int32 | Int64 | Float32 | Float64 | Bool).new
          converted_captures
          @data_types[index].each do |key, value|
            if match.named_captures.keys.includes?(key)
              value_to_convert = match.named_captures[key]
              if value_to_convert.is_a?(String)
                converted_captures[key] = case value
                when "int"
                  value_to_convert.to_i32
                when "long"
                  value_to_convert.to_i64
                when "float"
                  value_to_convert.to_f32
                when "double"
                  value_to_convert.to_f64
                when "boolean"
                  value_to_convert == "true"
                else
                  value_to_convert
                end
              end
            end
          end
          return match.named_captures.merge converted_captures
        end
      end
    end
    # no matches empty hash map
    {} of String => String
  end
end