require 'yaml'
require 'natto'
require 'mojinizer'
require 'tiny_segmenter'
require "i18n"

puts "loadingsongs"

master = {}

ts = TinySegmenter.new
nm = Natto::MeCab.new

# build with extract_dict.rb
dict = YAML.load_file("db/data/jpn.yml")

Dir["db/data/newsong/*.yml"].each do |file|
  p file

  data = YAML.load_file(file)
  data['result']['song'].each do |thesong|
    # - song_name: 青いメルヘン
    #   song_alias:
    #   esong_code: 1176B28
    #   t_singer_master_id: '2122'
    #   singer_name: 堀江 美都子
    #   singer_alias:
    #   available_date: '1970-01-01'
    #   end_date: '2999-04-10 00:00:00'
    #   tie_up: あたらしい日本の民話シリーズ<番組名>
    #   country_code: '0'
    #   content_type:
    #   song_name_ruby: あおいめるへん
    #   singer_name_ruby: ほりえみつこ
    #   song_variation:
    #   - esong_code: 1176B28
    #     song_name: 青いメルヘン
    #     content_type: ''

    master[thesong['esong_code']] ||= {
      song_name: thesong['song_name'],
      artist_name: thesong['singer_name'],
      artist_id: thesong['t_singer_master_id'],
      avbegin_date: thesong['available_date'],
      avend_date: thesong['end_date'],
      tie_up: thesong['tie_up'],
      song_name_ruby: thesong['song_name_ruby'],
      artist_name_ruby: thesong['singer_name_ruby'],
      content_type: thesong['content_type'],
      introcha: '',
      information: '',
      genre: '',
      file: file
    }
  end

end

Dir["db/data/data/*.yml"].each do |file|
  p file

  data = YAML.load_file(file)
  data[:songs].each do |esong_id, songinfo|

    # 4859A22:
    #   status: 'true'
    #   code: '200'
    #   messages: ''
    #   result:
    #     song_name: ジュラン☆ソウル
    #     esong_code: 4859A22
    #     content_type:
    #     singer_name: 浅沼 晋太郎
    #     t_singer_master_id: '47933'
    #     available_date: '1970-01-01 00:00:00'
    #     end_date: '2999-04-10 00:00:00'
    #     introcha: イケてる親父の恐竜パワー
    #     information: 特撮「機界戦隊ゼンカイジャー」イメージソング
    #     lyrics:
    #     composer:
    #     program_name: 機界戦隊ゼンカイジャー<番組名>
    #     genre_id: '7'
    #     genre_name: アニメ
    #     key_shift: '0'

    a = {
      song_name: master[esong_id]&.fetch(:song_name, nil),
      artist_name: master[esong_id]&.fetch(:artist_name, nil),
      artist_id: master[esong_id]&.fetch(:artist_id, nil),
      avbegin_date: master[esong_id]&.fetch(:avbegin_date, nil),
      avend_date: master[esong_id]&.fetch(:avend_date, nil),
      tie_up: master[esong_id]&.fetch(:tie_up, nil),
      song_name_ruby: master[esong_id]&.fetch(:song_name_ruby, nil),
      artist_name_ruby: master[esong_id]&.fetch(:artist_name_ruby, nil),
      content_type: master[esong_id]&.fetch(:content_type, nil),
      file: master[esong_id]&.fetch(:file, nil),

      a_song_name: songinfo['result']['song_name'],
      a_artist_name: songinfo['result']['singer_name'],
      a_artist_id: songinfo['result']['t_singer_master_id'],
      a_avbegin_date: songinfo['result']['available_date'],
      a_avend_date: songinfo['result']['end_date'],
      a_tie_up: songinfo['result']['program_name'],
      a_content_type: songinfo['result']['content_type'],
      a_introcha: songinfo['result']['introcha'],
      a_information: songinfo['result']['information'],
      a_genre: songinfo['result']['genre_name'],
      a_file: file
    }

    a[:f_song_name] = (a[:song_name] || a[:a_song_name])

    next if a[:f_song_name].nil?

    a[:s_song_name] = ts.segment(a[:f_song_name])

    a[:n_song_name] = nm.enum_parse(a[:f_song_name]).map do |x|
      z = x.feature.split(',').last
      z == '*' ? x.surface : z
    end.join('').hiragana


    rmj = dict[a[:f_song_name]] || dict[a[:f_song_name].gsub(/\s+/, '')]

    a[:romaji_song_name] = rmj&.each do |x|
      x.unicode_normalize(:nfd)&.downcase&.gsub(/[^a-z0-9]+/, ' ')
    end

    a[:r_song_name] = a[:romaji_song_name]&.first || a[:n_song_name].romaji.gsub(/[^a-z0-9]+/, '')

    a[:f_artist_name] = (a[:artist_name] || a[:a_artist_name])
    a[:s_artist_name] = ts.segment(a[:f_artist_name])

    if a[:f_artist_name].nil?
      p songinfo
      next
    end

    a[:n_artist_name] = nm.enum_parse(a[:f_artist_name]).map do |x|
      z = x.feature.split(',').last
      z == '*' ? x.surface : z
    end.join('').hiragana


    rmj = dict[a[:f_artist_name]] || dict[a[:f_artist_name].gsub(/\s+/, '')]

    a[:romaji_artist_name] = rmj&.each do |x|
      x.unicode_normalize(:nfd)&.downcase&.gsub(/[^a-z0-9]+/, ' ')
    end

    a[:r_artist_name] = a[:romaji_artist_name]&.first || a[:n_artist_name].romaji.gsub(/[^a-z0-9]+/, '')

    master[esong_id] = (master[esong_id] || {}).merge(a)
  end
  
end



File.write("db/data/master.yml", master.to_yaml)