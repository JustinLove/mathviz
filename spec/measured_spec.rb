require File.join('.', File.dirname(__FILE__), 'spec_helper')

class Subject
  include MathViz::Measured

  new_units :s

  def to_s
    "1"
  end
end

describe MathViz::Measured do
  before do
    @subject = Subject.new.s
  end

  it "should be created" do
    @subject.should_not be_nil
  end

  it "should have a unit in it's string" do
    @subject.with_units.should == " s"
  end

  it "should not have extra space if no unit" do
    Subject.new.with_units.should == ""
  end

  it "can have different units" do
    Subject.new.unit(:x).with_units.should == " x"
  end

  it "should create denominators" do
    Subject.new.per.s.with_units.should == " 1/s"
  end

  it "should have a shorthand for new units" do
    Subject.new_units(:m, :h)
    Subject.new.m.per.h.with_units.should == " m/h"
  end
end
