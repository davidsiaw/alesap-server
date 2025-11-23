class PaselaEsongPaselaArtist < ApplicationRecord
  has_paper_trail

    # pasela_esong_id is a istring
    ulid :song_id
    belongs_to :song, class_name: "PaselaEsong", foreign_key: :song_id

    # pasela_artist_id is a istring
    ulid :artist_id
    belongs_to :artist, class_name: "PaselaArtist", foreign_key: :artist_id

    validates_uniqueness_of :song, scope: :artist
    validates_presence_of :song
    validates_presence_of :artist

  def song_name
  	song.name.str
  end

  def code
  	song.esong_key
  end

  def artist_name
  	artist.artist_name.str
  end
end
