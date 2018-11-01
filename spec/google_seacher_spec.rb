require './lib/google_seacher'

describe GoogleSeacher do
  before(:each) do
    @google_seacher = GoogleSeacher.new('cats')
  end

  it 'should return link' do
    10.times do
      link = @google_seacher.next
      expect(link).to match(%r{http[s]?://.+})
    end
  end
end
