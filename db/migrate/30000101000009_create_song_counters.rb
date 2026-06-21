# frozen_string_literal: true

class CreateSongCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :song_counters, id: :uuid do |t|
      t.string :nickname, null: false
      t.string :song_code, null: false
      t.integer :count, null: false, default: 0
      t.datetime :updated_at
    end

    add_index :song_counters, :nickname
    add_index :song_counters, %i[nickname song_code]
  end
end
