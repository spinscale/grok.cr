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

  # TODO read standard patterns
  # TODO add custom patterns
  # TODO recursive detection
end
