require 'json'
require 'yaml'

dict = {}

# get karaokebase from mugen
Dir["karaokebase/tags/*.json"].each do |x|
	c = File.read(x)
	data = JSON.parse(c)

	next if data["tag"].nil?
	next if data["tag"]["i18n"].nil?

	jp = data["tag"]["i18n"]["jpn"]
	en = [
			data["tag"]["i18n"]["qro"],
			data["tag"]["i18n"]["eng"]
		].compact.uniq

	next if jp.nil?
	next if en.size.zero?

	dict[jp] = en

	p "#{jp} -> #{en}"
end

File.write("db/data/jpn.yml", dict.to_yaml)


