require File.join(File.dirname(__FILE__), 'spec_helper')

shared_examples_for "common combinations" do
  it "can be created" do
    @unit.should_not be_nil
  end

  it "flags a mismatch" do
    (@unit + MathViz::Unit.new(:x)).to_s.should == 'ERROR'
  end

  it "adds with same" do
    (@unit + @unit).to_s.should == @unit.to_s
  end

  it "multiplies with nothing" do
    (@unit * MathViz::Unit.new).to_s.should == @unit.to_s
  end

  it "divides with nothing" do
    (@unit / MathViz::Unit.new).to_s.should == @unit.to_s
  end

  it "cancels on division" do
    (@unit / @unit).should.to_s == ''
  end
end

describe "MathViz::Unit" do
  context "with no argument" do
    before do
      @unit = MathViz::Unit.new
    end

    it_should_behave_like "common combinations"

    it "has a blank representation" do
      @unit.to_s.should == ''
    end

    it "multiplies with numerator" do
      (@unit * MathViz::Unit.new(:x)).to_s.should == 'x'
    end

    it "divides with numerator" do
      (@unit / MathViz::Unit.new(:x)).to_s.should == '1/x'
    end

    it "multiplies with denominator" do
      (@unit * MathViz::Unit.new(:x => -1)).to_s.should == '1/x'
    end

    it "divides with denominator" do
      (@unit / MathViz::Unit.new(:x => -1)).to_s.should == 'x'
    end
  end

  context "with a single argument" do
    before do
      @unit = MathViz::Unit.new(:s)
    end

    it_should_behave_like "common combinations"

    it "has a simple representation" do
      @unit.to_s.should == "s"
    end
  end

  context "with a numerator argument" do
    before do
      @unit = MathViz::Unit.new(:s => 1)
    end

    it_should_behave_like "common combinations"

    it "has a simple representation" do
      @unit.to_s.should == "s"
    end

    it "multiplies with numerator" do
      ['s*x', 'x*s'].should include((@unit * MathViz::Unit.new(:x)).to_s)
    end

    it "divides with numerator" do
      (@unit / MathViz::Unit.new(:x)).to_s.should == 's/x'
    end

    it "multiplies with denominator" do
      (@unit * MathViz::Unit.new(:x => -1)).to_s.should == 's/x'
    end

    it "divides with denominator" do
      ['s*x', 'x*s'].should include((@unit / MathViz::Unit.new(:x => -1)).to_s)
    end

    it "cancels on multiplication" do
      (@unit * MathViz::Unit.new(:s => -1)).to_s.should == ''
    end
  end

  context "with a numerator squared argument" do
    before do
      @unit = MathViz::Unit.new(:s => 2)
    end

    it_should_behave_like "common combinations"

    it "has a double representation" do
      @unit.to_s.should == "s*s"
    end

    it "multiplies with numerator" do
      ['s*s*x', 'x*s*s'].should include((@unit * MathViz::Unit.new(:x)).to_s)
    end

    it "divides with numerator" do
      (@unit / MathViz::Unit.new(:x)).to_s.should == 's*s/x'
    end

    it "multiplies with denominator" do
      (@unit * MathViz::Unit.new(:x => -1)).to_s.should == 's*s/x'
    end

    it "divides with denominator" do
      ['s*s*x', 'x*s*s'].should include((@unit / MathViz::Unit.new(:x => -1)).to_s)
    end

    it "cancels on multiplication" do
      (@unit * MathViz::Unit.new(:s => -1)).to_s.should == 's'
    end

    it "increases on multiplication" do
      (@unit * MathViz::Unit.new(:s => 1)).to_s.should == 's*s*s'
    end
  end

  context "with a denominator argument" do
    before do
      @unit = MathViz::Unit.new(:s => -1)
    end

    it_should_behave_like "common combinations"

    it "has a 1 in the numerator position" do
      @unit.to_s.should == "1/s"
    end

    it "multiplies with numerator" do
      ['x/s'].should include((@unit * MathViz::Unit.new(:x)).to_s)
    end

    it "divides with numerator" do
      ['1/s*x', '1/x*s'].should include((@unit / MathViz::Unit.new(:x)).to_s)
    end

    it "multiplies with denominator" do
      ['1/s*x', '1/x*s'].should include((@unit * MathViz::Unit.new(:x => -1)).to_s)
    end

    it "divides with denominator" do
      ['x/s'].should include((@unit / MathViz::Unit.new(:x => -1)).to_s)
    end

    it "cancels on multiplication" do
      (@unit * MathViz::Unit.new(:s => 1)).to_s.should == ''
    end
  end

  context "with a complex argument" do
    before do
      @unit = MathViz::Unit.new(:V => 1, :A => 1, :h => -1)
    end

    it_should_behave_like "common combinations"

    it "has a complex representation" do
      ["V*A/h", "A*V/h"].should include(@unit.to_s)
    end

    it "cancels on multiplication" do
      ["V*A", "A*V"].should include((@unit * MathViz::Unit.new(:h)).to_s)
    end

    it "cancels on multiplication" do
      ["V/h"].should include((@unit * MathViz::Unit.new(:A => -1)).to_s)
    end
  end
end
