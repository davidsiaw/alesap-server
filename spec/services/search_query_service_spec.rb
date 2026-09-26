# frozen_string_literal: true

require 'rails_helper'

# The SQL is run for real by spec/apis/v1/search_api_spec.rb; these pin the choices in it.
RSpec.describe SearchQueryService do
  describe '#word_matches_sql' do
    it 'also matches stored readings that are a prefix of a long word (truncated readings)' do
      sql = described_class.new.word_matches_sql('あとはんすおすと', 0, [1, 2, 3, 4])

      expect(sql).to include("term IN ('あとはんす', 'あとはんすお', 'あとはんすおす') AND kind IN (2, 4)")
    end

    it 'skips truncated readings for words of 5 characters or less' do
      expect(described_class.new.word_matches_sql('あとはんす', 0, [1, 2])).not_to include('UNION ALL')
    end

    it 'skips truncated readings when the constraint has no reading kinds (tags)' do
      expect(described_class.new.word_matches_sql('あとはんすおすと', 0, [7])).not_to include('UNION ALL')
    end

    it 'limits the substring match to the given kinds' do
      expect(described_class.new.word_matches_sql('love', 3, [3, 4])).to include("LIKE '%love%' AND kind IN (3, 4)")
    end
  end

  describe '#ranked_sql' do
    it 'requires every word to match' do
      expect(described_class.new.ranked_sql(%w[advance australia], [1])).to include('HAVING count(*) = 2')
    end
  end

  describe '#search_sql' do
    it 'pages with LIMIT and OFFSET' do
      sql = described_class.new.search_sql(%w[love], kinds: [1], bangumi_v: false, page: 2, page_size: 20)

      expect(sql).to include('LIMIT 20 OFFSET 40')
    end

    it 'filters to 番組V songs when asked, and lists all of them when there are no words' do
      with_words = described_class.new.search_sql(%w[love], kinds: [1], bangumi_v: true, page: 0, page_size: 20)
      without = described_class.new.search_sql([], kinds: [1], bangumi_v: true, page: 0, page_size: 20)

      expect([with_words, without]).to match([/WHERE r\.id IN \(SELECT ix\.t_karaoke_master_id/,
                                              /WITH ranked AS \(SELECT DISTINCT t_karaoke_master_id AS id, 0 AS score/])
    end

    it 'does not filter by 番組V otherwise' do
      sql = described_class.new.search_sql(%w[love], kinds: [1], bangumi_v: false, page: 0, page_size: 20)

      expect(sql).not_to include('WHERE r.id IN')
    end
  end
end
