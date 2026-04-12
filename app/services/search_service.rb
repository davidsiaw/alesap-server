class SearchService
  attr_accessor :rows_per_page

  def initialize(search_term, page_num, page_size = 20)
    @search_term = search_term
    @page_num = page_num
    @page_size = page_size
  end

  def result
    res = perform_search(@search_term)

    # fallback on ruby
    if res[:total] == 0
      res = perform_search(@search_term.hiragana.unicode_normalize(:nfd).gsub(NormalizeService::REGEX, ''))
      res[:search] = @search_term
    end

    res
  end

  def perform_search(search)
    if search.gsub(/\s+/, '') == ''
      return {
        search: search,
        page: @page_num,
        total: 0,
        results: []
      }
    end

    exception_list = []
    if !search.include?('artist:')
      exception_list << "and token NOT like 'artist:%'"
    end

    if !search.include?('genre:')
      exception_list << "and token NOT like 'genre:%'"
    end

    if !search.include?('type:')
      exception_list << "and token NOT like 'type:%'"
    end

    sql = <<~SQL
      WITH r AS (
        SELECT "pasela_esongs"."esong_key", "priority" + 1000 as priority, str, token
        FROM "pasela_esongs"
        INNER JOIN "istrings" ON "istrings"."id" = "pasela_esongs"."name_id"
        INNER JOIN token_data ON token_data.esong_key = pasela_esongs.esong_key 
        WHERE (token LIKE $1)

        #{exception_list.join("\n")}

        GROUP BY "pasela_esongs"."esong_key", "istrings"."str", priority, token

        UNION

        SELECT "pasela_esongs"."esong_key", "priority" as priority, str, token
        FROM "pasela_esongs"
        INNER JOIN "istrings" ON "istrings"."id" = "pasela_esongs"."name_id"
        INNER JOIN token_data ON token_data.esong_key = pasela_esongs.esong_key 
        WHERE (token = $2) 

        #{exception_list.join("\n")}

        GROUP BY "pasela_esongs"."esong_key", "istrings"."str", priority, token
      ),
      k AS (
        SELECT esong_key, ROW_NUMBER() OVER (PARTITION BY esong_key ORDER BY priority, str) as rn, priority, str, token FROM r
        order by priority,str
      )

    SQL


    csql = sql + <<~SQL
      SELECT count(esong_key) FROM k
      WHERE rn = 1
    SQL

    cnt = PaselaEsong.lease_connection.select_all(csql, 
      'z',
      ["#{search.downcase}%", search.downcase]).to_a.flatten.first['count']


    lsql = sql + <<~SQL
      SELECT esong_key, str FROM k
      WHERE rn = 1
      LIMIT $3 OFFSET $4
    SQL

    raw = PaselaEsong.lease_connection.select_all(lsql, 
      'z',
      ["#{search.downcase}%", search.downcase, @page_size, @page_num * @page_size])

    codelist = raw.map{|x| x['esong_key']}


    ed = ExtraDatum.where(esong_key: codelist)

    songs = PaselaEsongPaselaArtist.
      joins(:song, :artist).
      merge(PaselaEsong.where(esong_key: codelist)).to_a

    edhash = {}

    ed.each do |x|
      edhash[x.esong_key] ||= {}
      edhash[x.esong_key][x.datatype] = x.value
    end

    shash = {}

    songs.each do |s|
      shash[s.code] = {
        song: s.song_name,
        artist: s.artist_name,
        extra: edhash[s.code] || {},
      }
    end


    # p ed

    res = codelist.
      map do |code|
        shash[code].merge(code: code)
      end

    {
      search: search,
      page: @page_num,
      total: cnt,
      results: [
        res
      ]
    }
  end
end
