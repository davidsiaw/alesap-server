# frozen_string_literal: true

# Adds English/romaji names from the name dictionary (db/data/jpn.yml, built from karaokebase
# by db/extract_dict.rb) to <schema>.terms, for PaselaSearchIndexBuilderService. The dictionary is
# loaded into <schema>.dictionary(jp, en).
#
# Matching on the normalised name means "*~アスタリスク~" in the dictionary matches Pasela's
# "*〜アスタリスク〜". The English names keep the kind of the name they matched.
#
#   PaselaDictionaryTermService.new.call('pasela_import', { 'オレンジレンジ' => ['ORANGE RANGE'] })
class PaselaDictionaryTermService
  # dictionary: { japanese name => [english/romaji names] }
  def call(schema, dictionary)
    @schema = schema
    @dictionary = dictionary
    create_dictionary_table
    insert_terms
  end

  private

  def conn
    ActiveRecord::Base.connection
  end

  def create_dictionary_table
    conn.execute("CREATE TABLE #{@schema}.dictionary (jp text, en text)")
    pg = conn.raw_connection
    pg.copy_data("COPY #{@schema}.dictionary (jp, en) FROM STDIN", PG::TextEncoder::CopyRow.new) do
      @dictionary.each { |jp, names| Array(names).each { |en| pg.put_copy_data([jp.to_s, en.to_s]) } }
    end
  end

  def insert_terms
    kinds = PaselaSearchIndexBuilderService::KINDS.values_at(:song_name, :singer_name, :tieup_name)
    conn.execute(<<~SQL.squish)
      INSERT INTO #{@schema}.terms (id, term, kind)
      SELECT DISTINCT t.id, #{@schema}.norm(d.en), t.kind
      FROM (SELECT #{@schema}.norm(jp) AS jp, en FROM #{@schema}.dictionary) d
      JOIN #{@schema}.terms t ON t.term = d.jp
      WHERE d.jp <> '' AND t.kind IN (#{kinds.join(', ')})
    SQL
  end
end
