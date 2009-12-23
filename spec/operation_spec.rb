require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'mathviz')

module Units
  new_units :s
end

describe Operation do
  describe Operation::Unary do
    it "can floor infinity" do
      (Constant.new(1.0/0).floor).data.should == "Infinity"
    end

    it "preserves units" do
      (Constant.new(1).s.floor).data.should == "1 s"
    end
  end

  describe Operation::Binary do
    it "reports ints as ints" do
      (Constant.new(1) * 2).data.should == "2"
    end

    it "doesn't croak on divide by zero" do
      (Constant.new(220) / 0).data.should == "Infinity"
    end

    it "preserves units" do
      (1.s * 2).data.should == "2 s"
    end
  end
end
