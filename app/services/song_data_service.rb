# frozen_string_literal: true

class SongDataService
  def self.build(esong_keys)
    return [] if esong_keys.empty?

    esong_keys = esong_keys.uniq
    extra_hash = build_extra_hash(esong_keys)
    song_hash = build_song_hash(esong_keys, extra_hash)

    esong_keys.filter_map do |code|
      entry = song_hash[code]
      entry ? entry.merge(code: code) : nil
    end
  end

  def self.build_extra_hash(esong_keys)
    {}.tap do |hash|
      ExtraDatum.where(esong_key: esong_keys).each do |ed|
        hash[ed.esong_key] ||= {}
        hash[ed.esong_key][ed.datatype] = ed.value
      end
    end
  end

  def self.build_song_hash(esong_keys, extra_hash)
    {}.tap do |hash|
      PaselaEsongPaselaArtist
        .joins(:song, :artist)
        .merge(PaselaEsong.where(esong_key: esong_keys))
        .each do |s|
          hash[s.code] = {
            song: s.song_name,
            artist: s.artist_name,
            extra: extra_hash[s.code] || {}
          }
        end
    end
  end
end
