require 'spec_helper'

describe LocomotiveTree do
  it 'has a version number' do
    expect(LocomotiveTree::VERSION).not_to be nil
  end

  it 'should register a tree tag in Liquid' do
    expect(::Liquid::Template.tags).to include('tree' => LocomotiveTree::Tree)
  end

  context 'setup liquid context' do 

    before(:each) do

    end

  end
end
