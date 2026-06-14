# frozen_string_literal: true

class SongCacheService
  def self.build(esong_keys)
    return [] if esong_keys.empty?

    esong_keys = esong_keys.uniq

    extra_data = ExtraDatum.where(esong_key: esong_keys)
    songs = PaselaEsongPaselaArtist
      .joins(:song, :artist)
      .merge(PaselaEsong.where(esong_key: esong_keys))

    extra_hash = {}
    extra_data.each do |ed|
      extra_hash[ed.esong_key] ||= {}
      extra_hash[ed.esong_key][ed.datatype] = ed.value
    end

    song_hash = {}
    songs.each do |s|
      song_hash[s.code] = {
        song: s.song_name,
        artist: s.artist_name,
        extra: extra_hash[s.code] || {}
      }
    end

    esong_keys.filter_map do |code|
      entry = song_hash[code]
      entry ? entry.merge(code: code) : nil
    end
  end
end
