class NormalizeService
  REGEX = /[^a-z0-9A-Z\p{Han}\p{Hiragana}\p{Katakana}ー]+/
  def initialize(str)
    @str = str
  end

  def toks

    ts = TinySegmenter.new
    nm = Natto::MeCab.new(nbest: 2)

    # ntoks = @str.split(REGEX).each_with_index.map do |tok, i|

    #   next if tok.length < 2

    #   {
    #     tok: tok.downcase,
    #     p:i+1
    #   }
    # end.compact

    ntoks = @str.split(REGEX).each_with_index.map do |tok, i|

      next if tok.length < 2

      a = tok.downcase.unicode_normalize(:nfd).gsub(REGEX, '')
      next if a == tok

      {
        tok: a,
        p:i+1 * 2
      }
    end.compact

    ntoks += @str.split(REGEX).each_with_index.map do |tok, i|

      next if tok.length < 2

      a = tok.downcase.unicode_normalize(:nfd).hiragana.gsub(REGEX, '')
      next if a == tok

      {
        tok: a,
        p:i+1 * 3
      }
    end.compact

    ntoks += @str.split(REGEX).each_with_index.map do |tok, i|

      next if tok.length < 2

      a = tok.downcase.romaji
      next if a == tok

      {
        tok: a,
        p:i+1 * 5
      }
    end.compact

    ntoks += nm.enum_parse(@str).each_with_index.map do |tok, i|

      z = tok.feature.split(',').last.downcase.romaji

      next if z == '*'
      next if z == ''

      {
        tok: tok.feature.split(',').last.downcase.romaji,
        p:i+1 * 7
      }
    end.compact

    ztoks = {}

    ntoks.each do |ntok|
      if ztoks[ntok[:tok]].nil? || ztoks[ntok[:tok]] < ntok[:p]
        ztoks[ntok[:tok]] = ntok[:p]
      end
    end
    
    p ztoks
  end
end

