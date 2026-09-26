# frozen_string_literal: true

# Prod's song_histories predates last_played_at: 30000101000008 was edited in place after prod
# had already run it, with last_played_date/last_played_time (strings). There the column is
# added instead of changed. The old columns are left alone (no data loss).
class ChangeLastPlayedAtToBigint < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:song_histories, :last_played_at)
      change_column :song_histories, :last_played_at, :bigint
    else
      add_column :song_histories, :last_played_at, :bigint
      add_index :song_histories, :last_played_at
    end
  end

  def down
    change_column :song_histories, :last_played_at, :integer
  end
end
