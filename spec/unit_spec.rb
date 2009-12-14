require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'matlat')

describe "Unit" do
  context "with no argument" do
    before do
      @unit = Unit.new
    end

    it "can be created" do
      @unit.should_not be_nil
    end

    it "has a blank representation" do
      @unit.to_s.should == ''
    end

    it "rejects a mismatch" do
      lambda {@unit + Unit.new(:s)}.should raise_error
    end
  end

  context "with a single argument" do
    before do
      @unit = Unit.new(:s)
    end

    it "can be created" do
      @unit.should_not be_nil
    end

    it "has a simple representation" do
      @unit.to_s.should == "s"
    end

    it "rejects a mismatch" do
      lambda {@unit + Unit.new(:h)}.should raise_error
    end
  end

  context "with a numerator argument" do
    before do
      @unit = Unit.new(:s => 1)
    end

    it "can be created" do
      @unit.should_not be_nil
    end

    it "has a simple representation" do
      @unit.to_s.should == "s"
    end

    it "rejects a mismatch" do
      lambda {@unit + Unit.new(:h)}.should raise_error
    end
  end

  context "with a denominator argument" do
    before do
      @unit = Unit.new(:s => -1)
    end

    it "can be created" do
      @unit.should_not be_nil
    end

    it "has a 1 in the numerator position" do
      @unit.to_s.should == "1/s"
    end

    it "rejects a mismatch" do
      lambda {@unit + Unit.new(:s)}.should raise_error
    end
  end

  context "with a complex argument" do
    before do
      @unit = Unit.new(:V => 1, :A => 1, :h => -1)
    end

    it "has a complex representation" do
      @unit.to_s.should == "A*V/h"
    end

    it "rejects a mismatch" do
      lambda {@unit + Unit.new(:s)}.should raise_error
    end
  end
end
