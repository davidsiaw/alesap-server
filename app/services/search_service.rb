class SearchService
  attr_accessor :rows_per_page

  def initialize(search_term)
    @search_term = search_term
  end

  def rel_basic_song
    @rel_basic_song ||= begin
      strs = Istring.where("str LIKE ?", "#{@search_term}%")

      songs = PaselaEsong.joins(:name).merge(strs)

      res = PaselaEsongPaselaArtist.
        joins(:song, :artist).
        merge(songs).
        limit(20)

      res
    end
  end

  def rel_basic_artist
    @rel_basic_artist ||= begin
      strs = Istring.where("str LIKE ?", "#{@search_term}%")

      artists = PaselaArtist.joins(:artist_name).merge(strs)

      res = PaselaEsongPaselaArtist.
        joins(:song, :artist).
        merge(artists).
        limit(20)

      res
    end
  end


  def result_relation
    return rel_basic_song if rel_basic_song.count > 0
    return rel_basic_artist if rel_basic_artist.count > 0

    []
  end

  def result
    res = result_relation.
      map do |x|
        {
          song: x.song_name,
          code: x.code,
          artist: x.artist_name
        }
      end

    {
      search: @search_term,
      total: result_relation.count,
      results: [
        res
      ]
    }
  end
end
