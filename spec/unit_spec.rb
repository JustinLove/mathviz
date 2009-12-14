require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'matlat')

describe "Unit" do
  context "with no argument" do
    it "can be created" do
      Unit.new.should_not be_nil
    end

    it "has a blank representation" do
      Unit.new.to_s.should == ''
    end
  end

  context "with a single argument" do
    it "can be created" do
      Unit.new(:s).should_not be_nil
    end

    it "has a simple representation" do
      Unit.new(:s).to_s.should == "s"
    end
  end
end
