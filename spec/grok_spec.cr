require "./spec_helper"

describe Grok do

  it "parses simple pattern" do
    grok = Grok.new [ "this is a %{GREEDYDATA:foo}" ]
    result = grok.parse "this is a test"
    result["foo"].should eq "test"
  end

  it "parses pattern with grok pattern in the middle" do
    grok = Grok.new [ "this is a %{GREEDYDATA:foo} bar" ]
    result = grok.parse "this is a test bar"
    result["foo"].should eq "test"
  end

  it "returns empty hash when pattern does not match" do
    grok = Grok.new [ "this is a %{INT:foo}" ]
    result = grok.parse "this is a test"
    result.empty?.should be_true
  end

  it "fails if no grok pattern is found" do
    expect_raises(Exception, "no grok pattern found") do
      grok = Grok.new [ "no pattern here!" ]
    end
  end

  it "fails when grok pattern is not closed" do
    expect_raises(Exception, "unclosed grok pattern starting at position 0") do
      grok = Grok.new [ "%{GREEDYDATA:foo unclosed" ]
    end
  end

  it "supports grok patterns without identifiers" do
    grok = Grok.new [ "%{GREEDYDATA} whatever" ]
    result = grok.parse "foo bar whatever"
    result.empty?.should be_true
  end

  it "supports custom patterns" do
    grok = Grok.new [ "color %{RGB:rgb}" ], { "RGB" => "RED|GREEN|BLUE" }
    result = grok.parse "color RED"
    result["rgb"].should eq "RED"
  end

  it "global patterns are not overwritten" do
    grok = Grok.new [ "%{INT:data}" ], { "INT" => "TEXT" }
    result = grok.parse "23"
    result["data"].should eq "23"
  end

  it "test dots do not get swallowed" do
    regex = Grok.convert_to_regex_string "%{A}.%{A}", { "A" => "1" }
    regex.should eq "1.1"
  end

  it "patterns can be nested" do
    grok = Grok.new [ "%{VERSION:version}" ], { "VERSION" => "%{INT}.%{INT}.%{INT}" }
    result = grok.parse "1.5.6"
    result["version"].should eq "1.5.6"
  end

  it "patterns can be nested really deep" do
    patterns = { "I_0" => "%{INT}" }
    (1..100).to_a.each { |idx| patterns["I_#{idx}"] = "%{I_#{idx-1}}" }
    grok = Grok.new [ "%{I_100:name}" ], patterns
    result = grok.parse "1024"
    result["name"].should eq "1024"
  end

  it "patterns can not go recursive" do
    expect_raises(Exception, /could not resolve the following patterns {"FOO" => "%{BAR}", "BAR" => "%{FOO}"}/) do
      Grok.new [ "%{FOO:data}" ], { "FOO" => "%{BAR}", "BAR" : "%{FOO}" }
    end
  end

  # TODO read standard patterns from file
  it "all the standard patterns are read" do
    grok = Grok.new [ "%{REDISTIMESTAMP:ts}" ]
    result = grok.parse "11 Dec 09:10:44"
    result["ts"].should eq "11 Dec 09:10:44"
  end

  # TODO speed up, resolve all standard patterns upfront
end
