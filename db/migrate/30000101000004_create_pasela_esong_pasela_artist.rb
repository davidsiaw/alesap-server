class CreatePaselaEsongPaselaArtist < ActiveRecord::Migration[5.2]
  def change
    create_table :pasela_esong_pasela_artists, id: :uuid do |t|

      t.references :song,
        null: false, index: true, foreign_key: { to_table: :pasela_esongs }

      t.references :artist,
        null: false, index: true, foreign_key: { to_table: :pasela_artists }


      t.datetime :updated_at

    end

    add_index :pasela_esong_pasela_artists, :updated_at

  end
end
