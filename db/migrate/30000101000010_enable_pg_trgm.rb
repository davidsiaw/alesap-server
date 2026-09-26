# frozen_string_literal: true

# Trigram indexes for substring search over pasela.terms (see PaselaSearchIndexBuilderService).
class EnablePgTrgm < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pg_trgm'
  end
end
