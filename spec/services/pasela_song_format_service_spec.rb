# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaselaSongFormatService do
  describe '#display_name' do
    it 'appends 【番組V】 to 番組V songs only' do
      names = [true, false].map { |v| described_class.new.display_name('song_name' => '勇者', 'bangumi_v' => v) }

      expect(names).to eq(%w[勇者【番組V】 勇者])
    end
  end

  describe '#extra' do
    it 'keeps the old newsong fields as strings, formats times, and leaves out nils and other columns' do
      row = { 't_karaoke_master_id' => 1, 'song_name' => '勇者', 'song_kana' => 'ゆうしや', 'singer_kana' => nil,
              'song_alias' => nil, 'available_date' => Time.utc(2026, 9, 18, 3, 5, 28), 'esong_code' => '5046B2' }

      expect(described_class.new.extra(row)).to eq(
        't_karaoke_master_id' => '1', 'song_name' => '勇者', 'song_kana' => 'ゆうしや',
        'song_name_ruby' => 'ゆうしや', 'available_date' => '2026-09-18T03:05:28'
      )
    end
  end

  describe '#details' do
    it 'returns song, artist, extra and code' do
      row = { 'song_name' => '勇者', 'singer_name' => 'YOASOBI', 'esong_code' => '5046B2', 'bangumi_v' => true }

      expect(described_class.new.details(row)).to eq(
        song: '勇者【番組V】', artist: 'YOASOBI', code: '5046B2',
        extra: { 'song_name' => '勇者', 'singer_name' => 'YOASOBI' }
      )
    end
  end
end
