require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'mathviz')

module Units
  new_units :s
end

describe Measured do
  it "works on numbers" do
    1.s.data.should == "1 s"
  end

  it "doesn't pollute" do
    1.to_s_with_units.should == "1"
  end
end
