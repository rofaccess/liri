require 'hash_extend'

RSpec.describe Hash, '#sample' do
  it 'devuelve un elemento aleatorio del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    expect(hash.sample).to be_a(Array)
  end
end