require 'runner/runner'

RSpec.describe Runner, '#run' do
  context 'getting runner from config file' do
    it 'return true' do
      expect(Runner.run).to be true
    end
  end

  context 'with custom runner' do
    it 'return true' do
      expect(Runner.current(:Second).run).to be true
    end
  end
end