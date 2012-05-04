require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

module MathViz::Units
  new_units :s
end

describe MathViz::Operation do
  describe 'unary' do
    it "can floor infinity" do
      (MathViz::Constant.new(1.0/0).floor).data.should == "Infinity"
    end

    it "preserves units" do
      (MathViz::Constant.new(1).s.floor).data.should == "1 s"
    end
  end

  describe 'binary' do
    it "reports ints as ints" do
      (MathViz::Constant.new(1) * 2).data.should == "2"
    end

    it "doesn't croak on divide by zero" do
      (MathViz::Constant.new(220) / 0).data.should == "Infinity"
    end

    it "preserves units" do
      (1.s * 2).data.should == "2 s"
    end
  end
end
