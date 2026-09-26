# frozen_string_literal: true

# The Pasela dump tables that TbldumpImportService loads. See docs/tbldump.md.
class TbldumpTableService
  # table => [primary key or nil, { column => type }]. Types were derived by scanning
  # every file of the 2026-09 dump. Columns that were always null are :text.
  ALL = {
    't_karaoke_master' => ['t_karaoke_master_id', {
      t_karaoke_master_id: :integer, song_name: :text, song_kana: :text, song_alias: :text,
      j_song_name: :text, j_song_kana: :text, t_singer_master_id: :integer,
      mt_country_code_id: :integer, karaoke_genre_id: :integer, mt_medley_id: :integer,
      mt_duet_id: :integer, medley_flg: :integer, remaked_id: :text, lights_flg: :integer,
      opus_cd: :text, information: :text, lyrics: :text, composer: :text,
      available_date: :timestamp, end_date: :timestamp, reg_date: :timestamp, upd_date: :timestamp
    }],
    't_song_variation' => ['t_song_variation_id', {
      t_song_variation_id: :integer, t_karaoke_master_id: :integer, esong_code: :text,
      song_name: :text, arrange_flg: :integer, play_count: :integer, del_flg: :integer,
      available_date: :timestamp, end_date: :timestamp, reg_date: :timestamp, upd_date: :timestamp,
      hash_esong_code: :text
    }],
    't_singer_master' => ['t_singer_master_id', {
      t_singer_master_id: :integer, singer_name: :text, singer_kana: :text, singer_alias: :text,
      j_singer_name: :text, j_singer_kana: :text, mt_gender_id: :integer,
      mt_country_code_id: :integer, singer_type: :integer, reg_date: :timestamp, upd_date: :timestamp
    }],
    'mt_introduction' => ['t_karaoke_master_id', {
      t_karaoke_master_id: :integer, introcha: :text, introcha_ruby: :text,
      reg_date: :timestamp, upd_date: :timestamp
    }],
    'mt_karaoke_genre' => ['mt_karaoke_genre_id', {
      mt_karaoke_genre_id: :integer, mt_content_type_id: :text, genre_name: :text,
      reg_date: :timestamp, upd_date: :timestamp
    }],
    'mt_country_code' => ['mt_country_code_id', {
      mt_country_code_id: :integer, name: :text, country_player_code: :integer, country_code: :text
    }],
    'mt_duet' => ['mt_duet_id', { mt_duet_id: :integer, duet_type: :text }],
    'mt_gender' => ['mt_gender_id', { mt_gender_id: :integer, gender_name: :text }],
    'mt_medley' => ['mt_medley_id', {
      mt_medley_id: :integer, medley_type: :text, reg_date: :timestamp, upd_date: :timestamp
    }],
    'mt_content_type' => ['mt_content_type_id', {
      mt_content_type_id: :integer, content_type_name: :text, content_indent: :text,
      reg_date: :timestamp, upd_date: :text
    }],
    't_tieup' => ['t_tieup_id', {
      t_tieup_id: :integer, program_name: :text, program_ruby: :text, program_information: :text,
      tbl_genre_singer_flg: :integer, available_date: :timestamp, end_date: :timestamp,
      reg_date: :timestamp, upd_date: :timestamp
    }],
    't_ix_karaoke_tieup' => [nil, { t_tieup_id: :integer, t_karaoke_master_id: :integer }],
    # Content type (DAM良音, JOYアカペラ, …): t_ix_arrange.mt_arrange_id -> mt_navi_genre.mt_arrange_id
    't_ix_arrange' => [nil, { t_song_variation_id: :integer, mt_arrange_id: :integer }],
    'mt_navi_genre' => ['navi_genre_id', {
      navi_genre_id: :integer, mt_arrange_id: :integer, navi_genre_theme_id: :integer, mt_duet_id: :integer,
      mt_medley_id: :integer, navi_genre_cd: :integer, navi_genre_name: :text, genre_panel_sort_key: :integer,
      children_type: :text, genre_sort_key: :integer, genre_header: :text, reg_date: :timestamp,
      upd_date: :timestamp, tbl_genre_song_flg: :integer, tbl_genre_new_song_flg: :integer,
      tbl_genre_singer_flg: :integer
    }],
    # Themes (国歌, クリスマス, 卒業, …)
    't_ix_navi_genre' => [nil, { t_karaoke_master_id: :integer, navi_genre_theme_id: :integer }],
    'mt_navi_genre_theme' => ['navi_genre_theme_id', {
      navi_genre_theme_id: :integer, navi_genre_name: :text, reg_date: :timestamp, upd_date: :timestamp
    }],
    't_karaoke_search' => ['t_karaoke_search_id', {
      t_karaoke_search_id: :integer, t_karaoke_master_id: :integer, song_name: :text,
      alias_flg: :integer, singer_no: :integer, reg_date: :timestamp, upd_date: :timestamp
    }],
    't_karaoke_ruby_search' => ['t_karaoke_ruby_search_id', {
      t_karaoke_ruby_search_id: :integer, t_karaoke_master_id: :integer, song_name_ruby: :text,
      song_ruby_num: :integer, country_id: :text, reg_date: :timestamp, upd_date: :timestamp
    }],
    't_singer_search' => ['t_singer_search_id', {
      t_singer_search_id: :integer, t_singer_master_id: :integer, singer_name: :text,
      notation_id: :integer, country_code: :text, reg_date: :timestamp, upd_date: :timestamp
    }],
    't_singer_ruby_search' => ['t_singer_ruby_search_id', {
      t_singer_ruby_search_id: :integer, t_singer_master_id: :integer, singer_name_ruby: :text,
      country_code: :text, singer_ruby_num: :integer, reg_date: :timestamp, upd_date: :timestamp
    }]
  }.freeze
end
