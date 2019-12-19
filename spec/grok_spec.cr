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

  it "fails when grok pattern misses identifier" do
    expect_raises(Exception, "missing identifier after colon at position 0") do
      grok = Grok.new [ "%{GREEDYDATA} whatever" ]
    end
  end

  # it "supports custom patterns" do
  #   grok = Grok.new [ "color %{RGB:rgb}" ], { "RGB" => "RED|GREEN|BLUE" }
  #   result = grok.parse "color RED"
  #   result["rgb"].should eq "RED"
  # end

  it "global patterns are not overwritten" do
    grok = Grok.new [ "%{INT:data}" ], { "INT" => "TEXT" }
    result = grok.parse "23"
    result["data"].should eq "23"
  end

  # TODO patterns can be nested
  it "patterns can be nested" do
    grok = Grok.new [ "%{VERSION:version}" ], { "VERSION" => "%{INT}.%{INT}.%{INT}" }
    result = grok.parse "1.5.6"
    result["version"].should eq "1.5.6"
  end

  # TODO patterns can be nested arbitrarily deep
  # TODO recursive detection
  # it "patterns can not go recursive" do
  #   grok = Grok.new [ "%{INT:data}" ], { "FOO" => "%{BAR}" }
  # end
  # TODO read standard patterns from file
end
