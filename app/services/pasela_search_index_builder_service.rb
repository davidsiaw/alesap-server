# frozen_string_literal: true

# Builds the search index over the raw Pasela tables, inside the given schema:
#
#   PaselaSearchIndexBuilderService.new.call('pasela_import', dictionary: {}, log: ImportLogService.new(logger))
#
# - <schema>.norm(text): see PaselaNormService.
# - <schema>.terms(id, term, kind): every searchable name/reading of a song, normalised.
#   id is t_karaoke_master_id. kind is one of KINDS. Tags (kind 7) are the genre, Pasela's
#   themes and the content type; tie-ups are not tags.
# - <schema>.dictionary(jp, en) and the English/romaji terms it adds: see PaselaDictionaryTermService.
class PaselaSearchIndexBuilderService
  KINDS = {
    song_name: 1, song_reading: 2,
    singer_name: 3, singer_reading: 4,
    tieup_name: 5, tieup_reading: 6,
    tag: 7
  }.freeze

  # dictionary: { japanese name => [english/romaji names] }; log: an ImportLogService
  def call(schema, dictionary:, log:)
    @schema = schema
    @dictionary = dictionary
    @log = log
    @log.step('search index: normaliser') { conn.execute(PaselaNormService.new.call(@schema)) }
    @log.step('search index: terms') { conn.execute(terms_sql) }
    @log.step("search index: dictionary (#{@dictionary.size} names)") do
      PaselaDictionaryTermService.new.call(@schema, @dictionary)
    end
    @log.step('search index: indexes') { create_indexes }
    @log.info("search index: #{conn.select_value("SELECT count(*) FROM #{@schema}.terms")} terms")
  end

  private

  def create_indexes
    conn.execute(<<~SQL.squish)
      DELETE FROM #{@schema}.terms WHERE term = '';
      CREATE INDEX terms_trgm ON #{@schema}.terms USING gin (term gin_trgm_ops);
      CREATE INDEX terms_term ON #{@schema}.terms (term);
      CREATE INDEX ix_karaoke_tieup_master ON #{@schema}.t_ix_karaoke_tieup (t_karaoke_master_id);
      CREATE UNIQUE INDEX song_variation_master ON #{@schema}.t_song_variation (t_karaoke_master_id);
      CREATE UNIQUE INDEX song_variation_code ON #{@schema}.t_song_variation (esong_code);
      CREATE INDEX ix_arrange_variation ON #{@schema}.t_ix_arrange (t_song_variation_id);
      CREATE INDEX ix_navi_genre_master ON #{@schema}.t_ix_navi_genre (t_karaoke_master_id);
      ANALYZE #{@schema}.terms;
    SQL
  end

  def conn
    ActiveRecord::Base.connection
  end

  def terms_sql
    <<~SQL.squish
      CREATE TABLE #{@schema}.terms AS
      SELECT DISTINCT id, #{@schema}.norm(term) AS term, kind::smallint AS kind FROM (
        #{song_sources}
        UNION ALL
        #{tag_sources}
        UNION ALL
        SELECT m.t_karaoke_master_id, s.term, s.kind
        FROM #{@schema}.t_karaoke_master m JOIN (#{singer_sources}) s USING (t_singer_master_id)
        UNION ALL
        SELECT ix.t_karaoke_master_id, x.term, x.kind
        FROM #{@schema}.t_ix_karaoke_tieup ix
        JOIN #{@schema}.t_tieup t USING (t_tieup_id)
        CROSS JOIN LATERAL (VALUES
          (regexp_replace(t.program_name, '<[^>]*>', '', 'g'), #{KINDS[:tieup_name]}),
          (t.program_ruby, #{KINDS[:tieup_reading]})
        ) x(term, kind)
      ) s
      WHERE term IS NOT NULL
    SQL
  end

  def song_sources
    <<~SQL.squish
      SELECT t_karaoke_master_id AS id, x.term, x.kind FROM #{@schema}.t_karaoke_master CROSS JOIN LATERAL
        #{values(song_name: %w[song_name song_alias j_song_name], song_reading: %w[song_kana j_song_kana])}
      UNION ALL SELECT t_karaoke_master_id, song_name, #{KINDS[:song_name]} FROM #{@schema}.t_karaoke_search
      UNION ALL SELECT t_karaoke_master_id, song_name_ruby, #{KINDS[:song_reading]}
        FROM #{@schema}.t_karaoke_ruby_search
    SQL
  end

  # Pasela's singer search tables also hold one row per tie-up (9,280 of each): in
  # t_singer_search the tie-up id is in notation_id and t_singer_master_id is an unrelated
  # singer; in t_singer_ruby_search the tie-up id is in t_singer_master_id. Skip them, or
  # e.g. every song by チェリッシュ matches 「葬送のフリーレン」 as a singer name.
  def singer_sources
    not_tieup = ->(col) { "NOT EXISTS (SELECT 1 FROM #{@schema}.t_tieup t WHERE t.t_tieup_id = #{col})" }
    <<~SQL.squish
      SELECT t_singer_master_id, x.term, x.kind FROM #{@schema}.t_singer_master CROSS JOIN LATERAL
        #{values(singer_name: %w[singer_name singer_alias j_singer_name], singer_reading: %w[singer_kana j_singer_kana])}
      UNION ALL SELECT t_singer_master_id, singer_name, #{KINDS[:singer_name]} FROM #{@schema}.t_singer_search
        WHERE #{not_tieup.call('notation_id')}
      UNION ALL SELECT t_singer_master_id, singer_name_ruby, #{KINDS[:singer_reading]}
        FROM #{@schema}.t_singer_ruby_search WHERE #{not_tieup.call('t_singer_master_id')}
    SQL
  end

  # Genre (except なし = none), theme, and content type (via the arrange id).
  def tag_sources
    <<~SQL.squish
      SELECT m.t_karaoke_master_id, g.genre_name, #{KINDS[:tag]}
        FROM #{@schema}.t_karaoke_master m
        JOIN #{@schema}.mt_karaoke_genre g ON g.mt_karaoke_genre_id = m.karaoke_genre_id
        WHERE g.genre_name <> 'なし'
      UNION ALL SELECT ix.t_karaoke_master_id, th.navi_genre_name, #{KINDS[:tag]}
        FROM #{@schema}.t_ix_navi_genre ix JOIN #{@schema}.mt_navi_genre_theme th USING (navi_genre_theme_id)
      UNION ALL SELECT v.t_karaoke_master_id, n.navi_genre_name, #{KINDS[:tag]}
        FROM #{@schema}.t_ix_arrange ix
        JOIN #{@schema}.t_song_variation v USING (t_song_variation_id)
        JOIN #{@schema}.mt_navi_genre n ON n.mt_arrange_id = ix.mt_arrange_id
    SQL
  end

  # (VALUES (column, kind), ...) x(term, kind), from { kind => [columns] }
  def values(columns_by_kind)
    rows = columns_by_kind.flat_map { |kind, columns| columns.map { |c| "(#{c}, #{KINDS.fetch(kind)})" } }
    "(VALUES #{rows.join(', ')}) x(term, kind)"
  end
end
