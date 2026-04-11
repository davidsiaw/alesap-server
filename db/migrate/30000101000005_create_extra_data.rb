class CreateExtraData < ActiveRecord::Migration[8.1]
  def change
    create_table :extra_data, id: :uuid do |t|
      t.string :esong_key
      t.string :datatype
      t.string :value

      t.datetime :updated_at
    end
    
    add_index :extra_data, :esong_key
    add_index :extra_data, :datatype
    add_index :extra_data, :value
  end
end
