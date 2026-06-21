# frozen_string_literal: true

class ChangeLastPlayedAtToBigint < ActiveRecord::Migration[8.1]
  def change
    change_column :song_histories, :last_played_at, :bigint
  end
end
