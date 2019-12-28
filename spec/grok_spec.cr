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
      Grok.new [ "no pattern here!" ]
    end
  end

  it "fails when grok pattern is not closed" do
    expect_raises(Exception, "unclosed grok pattern starting at position 0") do
      Grok.new [ "%{GREEDYDATA:foo unclosed" ]
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
    grok = Grok.new [ "%{A:first}.%{A:second}" ], { "A" => "1" }
    result = grok.parse "1.1"
    result["first"].should eq "1"
    result["second"].should eq "1"
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
    expect_raises(Exception, /pattern %{BAR} is defined recursive/) do
      Grok.new [ "%{FOO:data}" ], { "FOO" => "%{BAR}", "BAR" : "%{FOO}" }
    end
  end

  it "grok standard patterns - redis timestamps" do
    grok = Grok.new [ "%{REDISTIMESTAMP:ts}" ]
    result = grok.parse "11 Dec 09:10:44"
    result["ts"].should eq "11 Dec 09:10:44"
  end

  it "grok standard patterns - quoted string" do
    grok = Grok.new [ "%{QS:my_quoted_string}" ]
    result = grok.parse %q("quoted string")
    result["my_quoted_string"].should eq "\"quoted string\""
  end

  it "works with optional alternatives at the end" do
    grok = Grok.new [ "(?:%{GREEDYDATA:bytes}|-)" ]
    result = grok.parse "123"
    result["bytes"].should eq "123"
  end

  it "grok standard patterns - combined apache log" do
    grok = Grok.new [ "%{COMBINEDAPACHELOG}" ]
    result = grok.parse %q(1.1.1.1 - auth_user [12/Dec/2019:12:45:45 -0700] "GET / HTTP/1.1" 200 633 "http://referer.org" "Secret Browser")
    result.keys.should eq ["clientip", "ident", "auth", "timestamp", "verb", "request", "httpversion", "rawrequest", "response", "bytes", "referrer", "agent"]
  end

  it "works with type conversion" do
    grok = Grok.new [ "%{INT:my_int:int} %{INT:my_long:long} %{NUMBER:my_double:double} %{NUMBER:my_float:float} %{WORD:my_bool:boolean} %{WORD:my_string:string} %{WORD:second_string}" ]
    result = grok.parse "1 1 1.1 1.1 true whatever1 whatever2"

    result["my_int"].should eq 1_i32
    result["my_long"].should eq 1_i64
    result["my_double"].should eq 1.1_f64
    result["my_float"].should eq 1.1_f32
    result["my_bool"].should eq true
    result["my_string"].should eq "whatever1"
    result["second_string"].should eq "whatever2"
  end

  # TODO test with several grok expression in grok ctor array
end
