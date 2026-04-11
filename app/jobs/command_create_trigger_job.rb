class CommandCreateTriggerJob < ApplicationJob
  queue_as :default

  def perform(id)
  	cmd = Command.find(id)

    if cmd.verb == "loadbv"
      puts "loading bangumiv"

      bvhash = YAML.load_file('db/data/bvlist.yml')

      bvhash[:bangumi_v].each do |esong_code|
        data = ExtraDatum.find_or_initialize_by(
          esong_key: esong_code,
          datatype: 'tag_bv',
          value: '番組V'
        )
        data.save!
      end
    end

    if cmd.verb == "loadextra2"

      puts "loadingextra2"

      Dir["db/data/data/*.yml"].each_slice(10) do |files|
        ActiveRecord::Base.transaction do
          files.each do |file|
            puts "loadextra2 #{file}"

            data = YAML.load_file(file)
            data[:songs].each do |esong_code, reqresult|

              thesong = reqresult['result']

              thesong.each do |k, v|
                next if k == 'song_variation'
                next if k == 'esong_code'
                next if v.nil?

                data = ExtraDatum.find_or_initialize_by(
                  esong_key: thesong['esong_code'],
                  datatype: k,
                  value: v
                )
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

      Dir["db/data/newsong/*.yml"].each_slice(10) do |files|
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
                  datatype: k,
                  value: v
                )
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

      Dir["db/data/newsong/*.yml"].each_slice(10) do |files|
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
                esong_key: thesong['esong_code'],
                name: sname,
                ruby: sruby
              )
              song.save!

              artist = PaselaArtist.find_or_initialize_by(
                master_singer_id: thesong['t_singer_master_id'],
                artist_name: aname,
              )
              artist.save!

              obj = PaselaEsongPaselaArtist.find_or_initialize_by(
                song: song,
                artist: artist
              )
              obj.save!
            rescue => e
              p e

              p thesong

              return

            end
          end

        end
      end

    end

  end
end
