# frozen_string_literal: true

# Song search over the Pasela data loaded by `rake pasela:import` (pasela.terms, see
# PaselaSearchIndexBuilderService; SQL in SearchQueryService).
#
# The query is split on whitespace. Each word is normalised with pasela.norm, the same
# function the index was built with, and every word must match some term of the song,
# among the kinds allowed by the constraint (CONSTRAINTS: the search box's All / Title /
# Artist / Tags). Per word, the best match counts:
#   exact < prefix < contains < truncated reading (the stored reading is a prefix of
#   the word, because Pasela cuts readings short)
# and song matches rank before singer matches, which rank before tie-up matches.
# 番組V in the query is a filter, not a word (BangumiVService).
#
#   SearchService.new.call('フリーレン 番組V', 0) # => { search:, page:, total:, results: [[...]] }
class SearchService
  KINDS = PaselaSearchIndexBuilderService::KINDS
  # Tags (genre, theme, content type) are only searched when asked for; tie-ups only in all.
  CONSTRAINTS = {
    'all' => KINDS.values_at(:song_name, :song_reading, :singer_name, :singer_reading, :tieup_name, :tieup_reading),
    'title' => KINDS.values_at(:song_name, :song_reading),
    'artist' => KINDS.values_at(:singer_name, :singer_reading),
    'tags' => KINDS.values_at(:tag)
  }.freeze

  attr_reader :words, :hits, :total

  def call(search_term, page_num, page_size = 20, constraint: 'all')
    @search_term = search_term.to_s
    @page_num = [page_num.to_i, 0].max
    @page_size = page_size
    @kinds = CONSTRAINTS.fetch(constraint.to_s)
    @bangumi_v = BangumiVService.new.call(@search_term)
    @words = normalized_words
    @hits = @words.empty? && !@bangumi_v.requested? ? [] : conn.select_all(search_sql).to_a
    @total = @hits.first&.fetch('total') || 0
    result
  end

  private

  def conn
    ActiveRecord::Base.connection
  end

  # Normalised in the DB with the same function the index was built with. No words gives
  # ARRAY[NULL], and norm(NULL) is NULL, which compact_blank drops.
  def normalized_words
    words = @bangumi_v.text.split(/[[:space:]]+/).compact_blank
    sql = ActiveRecord::Base.sanitize_sql_array(['SELECT pasela.norm(x) FROM unnest(ARRAY[?]::text[]) x', words])
    conn.select_values(sql).compact_blank.uniq
  end

  def search_sql
    SearchQueryService.new.search_sql(@words, kinds: @kinds, bangumi_v: @bangumi_v.requested?,
                                              page: @page_num, page_size: @page_size)
  end

  def result
    songs = PaselaSongDetailService.new.by_master_id(@hits.pluck('id'))
    {
      search: @search_term,
      page: @page_num,
      total: @total,
      results: [@hits.filter_map { |hit| songs[hit['id']] }]
    }
  end
end
