# normalize_service_spec.rb
RSpec.describe NormalizeService do
  it 'normalizes' do
    n = NormalizeService.new('私 アイドル dayo あー')
    n.toks
  end
end
