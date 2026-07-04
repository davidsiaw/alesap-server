require 'singleton'

class SongMemoryService
  include Singleton

  attr_reader :song_cache

  NAME_FIELDS = %w[
    song_name
    song_name_ruby
    singer_name
    singer_name_ruby
    song_alias
    singer_alias
    introcha
    introcha_ruby
  ]

  def initialize
    load_all_songs!
  end

  def load_all_songs!
    return unless @song_cache.nil?

    @song_cache ||= {}

    Dir["db/data/newsong/*.yml"].each do |filename|
      p "loading datafile #{filename}"
      data = YAML.load_file(filename)

      data['result']['song'].each do |song|
        @song_cache[song['esong_code']] = song
      end
    end

    nil
  end

  def split(thing)
    res = []

    thing.split(/\s/).each do |x|
      toks = ts.segment(x)
      res += toks
    end

    res
  end

  def ts
    @ts ||= TinySegmenter.new
  end

  def inverse_index
    @inverse_index ||= begin
      result = {}

      @song_cache.each_with_index do |(esong_code, song), index|
        songname = song['song_name'].downcase

        puts index if index % 10000 == 0

        split(songname).each do |tok|
          result[tok] ||= Set.new
          result[tok] << esong_code
        end
      end
      
      result
    end
  end

  def search(search_term)
    @search_cache ||= {}

    search_term = search_term.downcase

    results = Set.new
    if @search_cache[search_term].nil?
      results_with_relevance = {}
      NAME_FIELDS.each do |field|
        subsearch_full(search_term, field).each do |code, relevance|
          results_with_relevance[code] ||= 0
          results_with_relevance[code] += relevance
        end
      end

      NAME_FIELDS.each do |field|
        subsearch_toks(search_term, field).each do |code, relevance|
          results_with_relevance[code] ||= 0
          results_with_relevance[code] += relevance
        end

        puts "> 3000 full cutoff"
        break if results_with_relevance.count > 3000
      end

      results = results_with_relevance.to_a.sort_by {|x| -x[1]}.map{|x| x[0]}
      @search_cache[search_term] = results

    else

      results = @search_cache[search_term]
    end

    results.to_a
  end

  def subsearch_full(term, field)
    p "subsearch_full #{term} #{field}"
    results = {}
    @song_cache.each do |esong_code, song|
      next if song[field].nil?
      if song[field].downcase.index(term) != nil
        results[esong_code] ||= 1_000_000
      end
    end
    results
  end

  def subsearch_toks(term, field)
    toks = split(term)

    results = {}

    toks.sort_by{|x| -x.length}.each do |tok|
      p "subsearch_toks #{tok} #{field}"
      @song_cache.each do |esong_code, song|
        next if song[field].nil?
        if song[field].downcase.index(tok) != nil
          results[esong_code] ||= 0
          results[esong_code] += 1
        end

        break if results.count > 1000
      end

      puts "> 1000 cutoff"
      break if results.count > 1000
    end

    results
  end

  def inspect
    '#<SongMemoryService>'
  end

end
