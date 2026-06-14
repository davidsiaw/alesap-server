# frozen_string_literal: true

class CreateSongHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :song_histories, id: :uuid do |t|
      t.string :nickname, null: false
      t.string :song_code, null: false
      t.string :last_played_date
      t.string :last_played_time
      t.datetime :updated_at
    end

    add_index :song_histories, :nickname
    add_index :song_histories, :song_code
  end
end
