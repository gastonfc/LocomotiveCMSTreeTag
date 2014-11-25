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
      @template=<<END
---
{% tree nodes %}
---
END
      @result=<<END
---
parent
---
END
    end

#     it 'should not break anything' do
#       template = Liquid::Template.parse(" Hello ")
#       result = template.render()
#
#       expect(result).to be == " Hello "
#     end
#
#     it 'should render a tree' do
#       template = Liquid::Template.parse(@template)
#       result = template.render()
#       expect(result).to be == @result
#     end

  end
end
