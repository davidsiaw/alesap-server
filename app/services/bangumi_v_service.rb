# frozen_string_literal: true

# 番組V: Pasela's theme for songs where the anime's own video plays during karaoke.
# In a query it's a filter, not a search word (SearchService); in results the song name
# gets a 【番組V】 marker (PaselaSongFormatService).
#
#   bangumi_v = BangumiVService.new.call('フリーレン 番組V')
#   bangumi_v.text        # => "フリーレン  " (the query without 番組V, NFKC-normalised)
#   bangumi_v.requested?  # => true
class BangumiVService
  THEME = '番組V'
  MARKER = "【#{THEME}】".freeze
  # Matched after NFKC, so 番組V, 番組v, 番組Ｖ, 番組ｖ all count, also glued to other text.
  QUERY_PATTERN = /番組v/i

  # t_karaoke_master_ids of 番組V songs, by theme name (not id) in case ids change.
  IDS_SQL = <<~SQL.squish
    SELECT ix.t_karaoke_master_id FROM pasela.t_ix_navi_genre ix
    JOIN pasela.mt_navi_genre_theme th USING (navi_genre_theme_id)
    WHERE th.navi_genre_name = '#{THEME}'
  SQL

  attr_reader :text

  def call(query)
    normalized = query.to_s.unicode_normalize(:nfkc)
    @text = normalized.gsub(QUERY_PATTERN, ' ')
    @requested = normalized.match?(QUERY_PATTERN)
    self
  end

  def requested?
    @requested
  end
end
