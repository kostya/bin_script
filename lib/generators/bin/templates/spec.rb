require File.dirname(__FILE__) + '/../spec_helper'

describe <%= class_name %>Script do
  before :each do
    @bin = <%= class_name %>Script.new

    # if want to point some params into bin => @bin.override_parameters({:i => 10, :a => '20'})
  end

  it 'should do! and not raise' do
    @bin.do!
  end
end
