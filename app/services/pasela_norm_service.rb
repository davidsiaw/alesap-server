# frozen_string_literal: true

# The one normaliser, created as the SQL function <schema>.norm(text) by
# PaselaSearchIndexBuilderService and used on both the indexed text and the query (SearchService).
# It follows Pasela's reading convention: NFKC, lower case, katakana -> hiragana,
# dakuten/handakuten and accents removed, small kana -> full size, and everything except
# letters/digits/kana/kanji/hangul dropped (spaces, punctuation, ー). See docs/search.md.
#
#   PaselaNormService.new.call('pasela') # => "CREATE FUNCTION pasela.norm(t text) ..."
class PaselaNormService
  KATAKANA = (0x30A1..0x30F6).map { |c| c.chr(Encoding::UTF_8) }.join
  HIRAGANA = (0x3041..0x3096).map { |c| c.chr(Encoding::UTF_8) }.join
  SMALL_KANA = 'ぁぃぅぇぉっゃゅょゎゕゖ'
  FULL_KANA = 'あいうえおつやゆよわかけ'
  KEEP = 'a-z0-9ぁ-ゖ㐀-䶿一-鿿豈-﫿々〆가-힣'

  # The CREATE FUNCTION statement for <schema>.norm.
  def call(schema)
    <<~SQL.squish
      CREATE FUNCTION #{schema}.norm(t text) RETURNS text
      LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE AS $$
        SELECT regexp_replace(
          translate(
            normalize(
              regexp_replace(
                normalize(translate(lower(normalize(t, NFKC)), '#{KATAKANA}', '#{HIRAGANA}'), NFD),
                '[\u0300-\u036f\u3099\u309a]', '', 'g'),
              NFC),
            '#{SMALL_KANA}', '#{FULL_KANA}'),
          '[^#{KEEP}]', '', 'g')
      $$
    SQL
  end
end
