class CommandCreateTriggerJob < ApplicationJob
  queue_as :default

  REGEX = /[^a-z0-9A-Z\p{Han}\p{Hiragana}\p{Katakana}＝]+/

  def perform(id)
  	cmd = Command.find(id)



    if cmd.verb == "loadtoken3"
      puts "building tokens from karaokebase"
      byname = {}

      jpn = YAML.load_file('db/data/jpn.yml')

      ActiveRecord::Base.transaction do
        Dir["db/data/newsong/*.yml"].each do |file|
          p file
          data = YAML.load_file(file)
          data['result']['song'].each do |info|
            esong_code = info['esong_code']
            c = info['result']['content_type'] || ''
            g = info['result']['genre_name']
            n = info['result']['song_name']
            s = info['result']['singer_name']

            t = {
              code: esong_code,
              raw: [],
              toks: []
            }

            if jpn[n]
              byname[c] ||= {}
              byname[c][g] ||= {}
              byname[c][g][s] ||= {}
              byname[c][g][s][n] ||= t

              t[:raw] += jpn[n]
            end

            if jpn[s]
              byname[c] ||= {}
              byname[c][g] ||= {}
              byname[c][g][s] ||= {}
              byname[c][g][s][n] ||= t

              t[:raw] += jpn[s]
            end

            set = Set.new
            t[:raw].each do |x|
              set += x.downcase.gsub('ô', 'ou').gsub('û', 'uu').gsub("'",'').split(' ')
              set << x.downcase.gsub('ô', 'ou').gsub('û', 'uu').gsub("'",'')
            end

            set.each do |tok|
              td = TokenDatum.find_or_initialize_by(esong_key: esong_code, token: tok)
              td.priority = 100000 / tok.length / tok.length
              td.save!
            end


          end
        end
      end
      
    end


    if cmd.verb == "loadtoken2"
      puts "building tokens from ruby"
      Dir["db/data/newsong/*.yml"].each do |file|
        p "rubyfrom #{file}"

        ActiveRecord::Base.transaction do
          data = YAML.load_file(file)
          data['result']['song'].each do |info|
            n = info['song_name_ruby']
            s = info['singer_name_ruby']

            td = TokenDatum.find_or_initialize_by(esong_key: info['esong_code'], token: n)
            td.priority = 10000
            td.save!

            td = TokenDatum.find_or_initialize_by(esong_key: info['esong_code'], token: s)
            td.priority = 100000
            td.save!
          end
        end
      end
    end


    if cmd.verb == "loadtoken"

      puts "building tokens"
      byname = {}

      Dir["db/data/newsong/*.yml"].each do |file|
        p file
        data = YAML.load_file(file)
        data['result']['song'].each do |info|
          esong_code = info['esong_code']
          c = info['result']['content_type'] || ''
          g = info['result']['genre_name']
          n = info['result']['song_name']
          s = info['result']['singer_name']
          byname[c] ||= {}
          byname[c][g] ||= {}
          byname[c][g][s] ||= {}
          byname[c][g][s][n] ||= []

          byname[c][g][s][n] << esong_code
        end
      end

      notwords = %w[
        feat
        the
        a
      ]

      output = {}

      byname.each do |c, cinfo|

        ctoks = c.split(REGEX).each_with_index.map do |tok, i|

          next if tok.length < 2
          next if notwords.include?(tok)

          {
            tok: tok.downcase,
            p:(i + 1) * 10000
          }
        end.compact

        hctoks = c.split(REGEX).each_with_index.map do |tok, i|

          next if tok.length < 2
          next if notwords.include?(tok)

          {
            tok: "type:#{tok.downcase}",
            p:i
          }
        end.compact
        
        cinfo.each do |g, ginfo|

          p "genre: #{g}"

          gtoks = g.split(REGEX).each_with_index.map do |tok, i|

            next if tok.length < 2
            next if notwords.include?(tok)

            {
              tok: tok.downcase,
              p:(i + 1) * 1000
            }
          end.compact

          hgtoks = g.split(REGEX).each_with_index.map do |tok, i|

            next if tok.length < 2
            next if notwords.include?(tok)

            {
              tok: "genre:#{tok.downcase}",
              p:i
            }
          end.compact


            ginfo.each do |s, ninfo|

              ActiveRecord::Base.transaction do

              p "load #{s}"

              if s.nil?
                p "s=#{s.inspect} #{ninfo.inspect}"
                next
              end
              stoks = s.split(REGEX).each_with_index.map do |tok, i|

                next if tok.length < 2
                next if notwords.include?(tok)

                {
                  tok: tok.downcase,
                  p:(i + 2) * 100
                }
              end.compact

              hstoks = s.split(REGEX).each_with_index.map do |tok, i|

                next if tok.length < 2
                next if notwords.include?(tok)

                {
                  tok: "artist:#{tok.downcase}",
                  p: i
                }
              end.compact

              ninfo.each do |n, codes|


                ntoks = n.split(REGEX).each_with_index.map do |tok, i|

                  next if tok.length < 2
                  next if notwords.include?(tok)

                  {
                    tok: tok.downcase,
                    p:(i + 1) * 100
                  }
                end.compact

                n2tokposes = n.enum_for(:scan, REGEX).map{Regexp.last_match.begin(0)}

                n2toks = []
                n2tokposes.each_with_index do |tokpos, i|
                  n2toks << {
                    tok: n[0..tokpos].downcase.rstrip,
                    p: n2tokposes.length - i
                  }
                end

                hightok = [
                  { tok: n.downcase, p:0 }
                ]

                toks = n2toks + ntoks + hightok + stoks + ctoks + gtoks + hstoks + hctoks + hgtoks

                output[c] ||= {}
                output[c][g] ||= {}
                output[c][g][s] ||= {}
                output[c][g][s][n] = {
                  tokens: toks,
                  codes: codes
                }

                toks.each do |tok|
                  codes.each do |code|
                    TokenDatum.create!(esong_key: code, token: tok[:tok], priority: tok[:p])
                  end
                end

              end # ActiveRecord::Base.transaction do
            end 
          end 

        end 

      end



      # File.write('db/byname.yml', byname.to_yaml)

    end

    if cmd.verb == "loadextra2"

      puts "loadingextra2"

      Dir["db/data/newsong/*.yml"].each_slice(1) do |files|
        ActiveRecord::Base.transaction do
          files.each do |file|
            puts "loadextra2 #{file}"

            data = YAML.load_file(file)
            data['result']['song'].each do |reqresult|
              esong_code = reqresult['esong_code']

              thesong = reqresult['result']

              thesong.each do |k, v|
                next if k == 'song_variation'
                next if k == 'esong_code'
                next if v.nil?

                data = ExtraDatum.find_or_initialize_by(
                  esong_key: thesong['esong_code'],
                  datatype: k
                )
                data.value = v
                data.save!
              end

            rescue => e
              p e

              p thesong

              return

            end
          end
        end
      end

    end

    if cmd.verb == "loadextra"

      puts "loadingextra"

      Dir["db/data/newsong/*.yml"].each_slice(1) do |files|
        ActiveRecord::Base.transaction do
          files.each do |file|
            puts "loadextra #{file}"

            data = YAML.load_file(file)
            data['result']['song'].each do |thesong|
              thesong.each do |k, v|
                next if k == 'song_variation'
                next if k == 'esong_code'
                next if v.nil?

                data = ExtraDatum.find_or_initialize_by(
                  esong_key: thesong['esong_code'],
                  datatype: k
                )
                data.value = v
                data.save!
              end

            rescue => e
              p e

              p thesong

              return

            end
          end
        end
      end

    end

    if cmd.verb == "loadsongs"

      puts "loadingsongs"

      Dir["db/data/newsong/*.yml"].each_slice(1) do |files|
        ActiveRecord::Base.transaction do
          files.each do |file|
          p file

            data = YAML.load_file(file)
            data['result']['song'].each do |thesong|

              sname = Istring.find_or_initialize_by(str: thesong['song_name'])
              sname.save!

              sruby = Istring.find_or_initialize_by(str: thesong['song_name_ruby'])
              sruby.save!

              aname = Istring.find_or_initialize_by(str: thesong['singer_name'])
              aname.save!

              song = PaselaEsong.find_or_initialize_by(
                esong_key: thesong['esong_code']
              )
              song.name = sname
              song.ruby = sruby
              song.save!

              artist = PaselaArtist.find_or_initialize_by(
                master_singer_id: thesong['t_singer_master_id']
              )
              artist.artist_name = aname
              artist.save!

              obj = PaselaEsongPaselaArtist.find_or_initialize_by(
                song: song,
                artist: artist
              )
              obj.save!
            rescue => e
              p e

              p artist

              p thesong


            end
          end

        end
      end

    end

  end
end
