class CommandCreateTriggerJob < ApplicationJob
  queue_as :default

  def perform(id)
  	cmd = Command.find(id)

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
