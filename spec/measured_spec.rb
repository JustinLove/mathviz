require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'matlat')

class Subject
  include Measured
end

describe Measured do
  before do
    @subject = Subject.new
  end

  it "should be created" do
    @subject.should_not be_nil
  end
end
