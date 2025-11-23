class CreatePaselaEsong < ActiveRecord::Migration[5.2]
  def change
    create_table :pasela_esongs, id: :uuid do |t|

      t.string :esong_key,
      	null: false, default: ''

      t.references :name,
        null: false, index: true, foreign_key: { to_table: :istrings }

      t.references :ruby,
        null: false, index: true, foreign_key: { to_table: :istrings }


      t.datetime :updated_at

    end

    add_index :pasela_esongs, :esong_key

    add_index :pasela_esongs, :updated_at

  end
end
