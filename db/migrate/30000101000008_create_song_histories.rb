# frozen_string_literal: true

class CreateSongHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :song_histories, id: :uuid do |t|
      t.string :nickname, null: false
      t.string :song_code, null: false
      t.integer :last_played_at
      t.datetime :updated_at
    end

    add_index :song_histories, :nickname
    add_index :song_histories, :song_code
    add_index :song_histories, :last_played_at
  end
end
