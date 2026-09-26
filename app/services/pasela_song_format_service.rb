# frozen_string_literal: true

# Turns a row of PaselaSongDetailService::QUERY into the song details the frontend expects
# (same shape as the old token search): { song:, artist:, extra:, code: }.
#
#   PaselaSongFormatService.new.details(row) # => { song: '勇者【番組V】', artist: 'YOASOBI', ... }
class PaselaSongFormatService
  # The old newsong field names. Values become strings; nils are left out.
  EXTRA_COLUMNS = %w[
    t_karaoke_master_id song_name song_kana song_alias j_song_name j_song_kana
    t_singer_master_id singer_name singer_alias mt_country_code_id karaoke_genre_id genre_name
    mt_duet_id mt_medley_id medley_flg lights_flg information introcha introcha_ruby
    available_date end_date reg_date upd_date tie_up tie_up_ruby content_type
  ].freeze

  def details(row)
    { song: display_name(row), artist: row['singer_name'], extra: extra(row), code: row['esong_code'] }
  end

  # 番組V songs get BangumiVService::MARKER after the name.
  def display_name(row)
    row['bangumi_v'] ? "#{row['song_name']}#{BangumiVService::MARKER}" : row['song_name']
  end

  # extra.song_name stays the raw title; times are formatted like the old data.
  def extra(row)
    extra = row.slice(*EXTRA_COLUMNS)
    extra['song_name_ruby'] = row['song_kana']
    extra['singer_name_ruby'] = row['singer_kana']
    extra.compact.transform_values { |v| v.respond_to?(:strftime) ? v.strftime('%Y-%m-%dT%H:%M:%S') : v.to_s }
  end
end
