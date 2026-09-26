# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BangumiVService do
  describe '#call' do
    it 'takes 番組V out of the query in any case or width, even glued to other text' do
      results = ['フリーレン 番組V', 'フリーレン番組v', 'フリーレン 番組Ｖ', '番組ｖフリーレン'].map do |query|
        bangumi_v = described_class.new.call(query)
        [bangumi_v.text.split, bangumi_v.requested?]
      end

      expect(results).to all(eq([['フリーレン'], true]))
    end

    it 'leaves a query without 番組V alone, apart from NFKC' do
      bangumi_v = described_class.new.call('ｶﾞﾝﾀﾞﾑ 番組')

      expect([bangumi_v.text, bangumi_v.requested?]).to eq(['ガンダム 番組', false])
    end
  end
end
