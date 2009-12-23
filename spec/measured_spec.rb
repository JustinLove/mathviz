require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'mathviz')

class Subject
  include Measured

  new_units :s

  def to_s
    "1"
  end
end

describe Measured do
  before do
    @subject = Subject.new.s
  end

  it "should be created" do
    @subject.should_not be_nil
  end

  it "should have a unit in it's string" do
    @subject.to_s_with_units.should == "1 s"
  end

  it "should not have extra space if no unit" do
    Subject.new.to_s_with_units.should == "1"
  end

  it "can have different units" do
    Subject.new.unit(:x).to_s_with_units.should == "1 x"
  end

  it "should create denominators" do
    Subject.new.per.s.to_s_with_units.should == "1 1/s"
  end

  it "should have a shorthand for new units" do
    Subject.new_units(:m, :h)
    Subject.new.m.per.h.to_s_with_units.should == "1 m/h"
  end
end
