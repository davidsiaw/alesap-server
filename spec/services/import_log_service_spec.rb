# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportLogService do
  describe '#step' do
    it 'logs the label with how long the block took, and returns the block result' do
      out = StringIO.new

      result = described_class.new(Logger.new(out)).step('added primary keys') { :done }

      expect([result, out.string]).to match([:done, /added primary keys\s+\d+\.\ds/])
    end
  end

  describe '#progress' do
    it 'logs at every 10% of the files and at the end, with running row totals' do
      out = StringIO.new
      progress = described_class.new(Logger.new(out)).progress(25)

      25.times { progress.tick(100) }

      expect(out.string.scan(%r{loaded (\d+)/25 files \((\d+)%\), (\d+) rows}))
        .to eq([%w[3 12 300], %w[5 20 500], %w[8 32 800], %w[10 40 1000], %w[13 52 1300], %w[15 60 1500],
                %w[18 72 1800], %w[20 80 2000], %w[23 92 2300], %w[25 100 2500]])
    end
  end
end
