# frozen_string_literal: true

# Song details by song code, from the pasela schema (`rake pasela:import`): the /song
# endpoint, the favourites/history `cache`, and the /queue code check.
#
#   SongDataService.new.build(['5046B2', 'NOPE']) # => [{ song: '勇者【番組V】', ..., code: '5046B2' }]
#   SongDataService.new.exists?('5046B2')        # => true
class SongDataService
  # Details for each code (same shape as search results), in the given order.
  # Codes that aren't in the dump are left out.
  def build(codes)
    codes = codes.uniq
    details = PaselaSongDetailService.new.by_code(codes)
    codes.filter_map { |code| details[code] }
  end

  def exists?(code)
    sql = ActiveRecord::Base.sanitize_sql_array(['SELECT 1 FROM pasela.t_song_variation WHERE esong_code = ?', code])
    ActiveRecord::Base.connection.select_value(sql).present?
  end
end
