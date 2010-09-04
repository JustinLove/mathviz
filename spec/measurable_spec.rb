require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

module MathViz::Units
  new_units :s
end

describe MathViz::Measured do
  it "works on numbers" do
    1.s.data.should == "1 s"
  end
end
