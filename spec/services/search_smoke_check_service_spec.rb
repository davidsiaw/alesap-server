# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchSmokeCheckService do
  describe '#found?' do
    it 'needs song and artist to match on the same result, case-insensitively' do
      check = { 'song' => 'アスタリスク', 'artist' => 'orange range' }
      same = [{ song: 'Asterisk', artist: '嵐' }, { song: '*〜アスタリスク〜', artist: 'ORANGE RANGE' }]
      split = [{ song: '*〜アスタリスク〜', artist: 'SCANDAL' }, { song: 'Other', artist: 'ORANGE RANGE' }]

      expect([described_class.new.found?(check, same), described_class.new.found?(check, split)]).to eq([true, false])
    end
  end

  describe '#report' do
    it 'shows PASS, or FAIL with the top 3 results' do
      check = { 'query' => 'asterisk', 'song' => 'アスタリスク', 'artist' => 'orange range' }
      results = [{ song: 'A', artist: '1' }, { song: 'B', artist: '2' }, { song: 'C', artist: '3' }, { song: 'D' }]

      expect([described_class.new.report(check, true, results), described_class.new.report(check, false, results)])
        .to eq(['PASS  "asterisk" -> アスタリスク / orange range',
                "FAIL  \"asterisk\" -> アスタリスク / orange range\n      got: A / 1 | B / 2 | C / 3"])
    end
  end

  describe '#call' do
    it 'runs each check of the file (spec/fixtures/search_smoke.yml) and returns the failures' do
      results = [{ song: '*〜アスタリスク〜', artist: 'SCANDAL' }]
      allow(SearchService).to receive(:new).and_return(instance_double(SearchService, call: { results: [results] }))
      out = StringIO.new

      failures = described_class.new.call('spec/fixtures/search_smoke.yml', out: out)

      expect([failures.pluck('query'), out.string.lines.last])
        .to eq([['asterisk'], "0 of 1 search smoke checks passed\n"])
    end
  end
end
