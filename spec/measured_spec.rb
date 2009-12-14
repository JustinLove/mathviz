require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'matlat')

class Subject
  include Measured

  def to_s
    "1"+ unit_s
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
    @subject.to_s.should == "1 s"
  end

  it "can have different units" do
    Subject.new.unit(:x).to_s.should == "1 x"
  end

  it "should create denominators" do
    Subject.new.per.s.to_s.should == "1 1/s"
  end
end
