class CreatePaselaArtist < ActiveRecord::Migration[5.2]
  def change
    create_table :pasela_artists, id: :uuid do |t|
      t.references :artist_name,
        null: false, index: true, foreign_key: { to_table: :istrings }

      t.string :master_singer_id,
        null: false, default: ''

      t.datetime :updated_at
    end

    add_index :pasela_artists, :master_singer_id
    add_index :pasela_artists, :updated_at
  end
end
