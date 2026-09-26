# frozen_string_literal: true

# Song details from the pasela schema, formatted by PaselaSongFormatService.
#
#   PaselaSongDetailService.new.by_code(['5046B2']) # => { '5046B2' => { song: '勇者【番組V】', ... } }
class PaselaSongDetailService
  # First tie-up of the song (all of them are searchable; the old field held one).
  TIE_UP = <<~SQL.squish
    SELECT t.program_name AS tie_up, t.program_ruby AS tie_up_ruby
    FROM pasela.t_ix_karaoke_tieup ix JOIN pasela.t_tieup t USING (t_tieup_id)
    WHERE ix.t_karaoke_master_id = m.t_karaoke_master_id
    ORDER BY t.t_tieup_id LIMIT 1
  SQL

  # Content type (DAM良音, …) via the variation's arrange id.
  CONTENT_TYPE = <<~SQL.squish
    SELECT n.navi_genre_name AS content_type
    FROM pasela.t_ix_arrange ix JOIN pasela.mt_navi_genre n ON n.mt_arrange_id = ix.mt_arrange_id
    WHERE ix.t_song_variation_id = v.t_song_variation_id
    ORDER BY n.navi_genre_id LIMIT 1
  SQL

  QUERY = <<~SQL.squish
    SELECT m.*, v.esong_code, s.singer_name, s.singer_kana, s.singer_alias, g.genre_name,
           i.introcha, i.introcha_ruby, tie.tie_up, tie.tie_up_ruby, ct.content_type,
           m.t_karaoke_master_id IN (#{BangumiVService::IDS_SQL}) AS bangumi_v
    FROM pasela.t_karaoke_master m
    JOIN pasela.t_song_variation v USING (t_karaoke_master_id)
    LEFT JOIN pasela.t_singer_master s USING (t_singer_master_id)
    LEFT JOIN pasela.mt_karaoke_genre g ON g.mt_karaoke_genre_id = m.karaoke_genre_id
    LEFT JOIN pasela.mt_introduction i USING (t_karaoke_master_id)
    LEFT JOIN LATERAL (#{TIE_UP}) tie ON true
    LEFT JOIN LATERAL (#{CONTENT_TYPE}) ct ON true
  SQL

  # { t_karaoke_master_id => details }
  def by_master_id(ids)
    return {} if ids.empty?

    fetch('m.t_karaoke_master_id', ids)
  end

  # { esong_code => details }
  def by_code(codes)
    return {} if codes.empty?

    fetch('v.esong_code', codes)
  end

  private

  def fetch(column, values)
    sql = ActiveRecord::Base.sanitize_sql_array(["#{QUERY} WHERE #{column} IN (?)", values])
    ActiveRecord::Base.connection.select_all(sql).to_a.to_h { |row| [row[column.split('.').last], formatter.details(row)] }
  end

  def formatter
    @formatter ||= PaselaSongFormatService.new
  end
end
