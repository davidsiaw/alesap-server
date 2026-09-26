# frozen_string_literal: true

# Builds SearchService's SQL over pasela.terms.
#
# The words go in as constants (not a CTE) so the planner can use the trigram and btree
# indexes; with a CTE it can't estimate the rows and scans all of terms. The words come
# from pasela.norm, which strips %, _ and \, so they're safe inside LIKE.
#
#   SearchQueryService.new.search_sql(%w[あすたりすく], kinds: [1, 2], bangumi_v: false, page: 0, page_size: 20)
class SearchQueryService
  # A stored reading shorter than this never matches as "truncated reading", otherwise
  # short readings like "こ" would match every query starting with こ.
  MIN_TRUNCATED_READING = 5
  READING_KINDS = PaselaSearchIndexBuilderService::KINDS.values_at(:song_reading, :singer_reading, :tieup_reading)
                                                        .freeze
  # With only 番組V and no words, every 番組V song matches (score 0).
  ALL_BANGUMI_V_SQL = <<~SQL.squish.freeze
    SELECT DISTINCT t_karaoke_master_id AS id, 0 AS score FROM (#{BangumiVService::IDS_SQL}) b
  SQL

  # One page of [id, total] rows, best first.
  def search_sql(words, kinds:, bangumi_v:, page:, page_size:)
    ranked = words.empty? ? ALL_BANGUMI_V_SQL : ranked_sql(words, kinds)
    <<~SQL.squish
      WITH ranked AS (#{ranked})
      SELECT r.id, count(*) OVER () AS total
      FROM ranked r JOIN pasela.t_karaoke_master m ON m.t_karaoke_master_id = r.id
      #{"WHERE r.id IN (#{BangumiVService::IDS_SQL})" if bangumi_v}
      ORDER BY r.score, m.song_kana, r.id
      LIMIT #{page_size.to_i} OFFSET #{page.to_i * page_size.to_i}
    SQL
  end

  # Per word the best match counts (song < singer < tie-up); every word must match.
  def ranked_sql(words, kinds)
    matches = words.each_with_index.map { |w, i| word_matches_sql(w, i, kinds) }.join(' UNION ALL ')
    <<~SQL.squish
      SELECT id, sum(score) AS score FROM (
        SELECT id, w, min(quality + CASE WHEN kind <= 2 THEN 0 WHEN kind <= 4 THEN 4 ELSE 8 END) AS score
        FROM (#{matches}) m GROUP BY id, w
      ) per_word GROUP BY id HAVING count(*) = #{words.size}
    SQL
  end

  # Terms matching one word: exact 0, prefix 1, contains 2, and 3 for a truncated reading
  # (a stored reading that's a prefix of the word, because Pasela cuts readings short).
  def word_matches_sql(word, index, kinds)
    sql = <<~SQL.squish
      SELECT id, #{index} AS w, kind,
             CASE WHEN term = #{conn.quote(word)} THEN 0 WHEN term LIKE #{conn.quote("#{word}%")} THEN 1 ELSE 2 END AS quality
      FROM pasela.terms WHERE term LIKE #{conn.quote("%#{word}%")} AND kind IN (#{kinds.join(', ')})
    SQL
    prefixes = (MIN_TRUNCATED_READING...word.length).map { |n| word[0, n] }
    reading_kinds = READING_KINDS & kinds
    return sql if prefixes.empty? || reading_kinds.empty?

    sql + " UNION ALL SELECT id, #{index}, kind, 3 FROM pasela.terms " \
          "WHERE term IN (#{prefixes.map { |p| conn.quote(p) }.join(', ')}) AND kind IN (#{reading_kinds.join(', ')})"
  end

  private

  def conn
    ActiveRecord::Base.connection
  end
end
