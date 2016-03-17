require 'spec_helper'
describe 'secrets' do

  context 'with defaults for all parameters' do
    it { should contain_class('secrets') }
  end
end
