class CreateTokenData < ActiveRecord::Migration[8.1]
  def change
    create_table :token_data, id: :uuid do |t|
      t.string :esong_key
      t.string :token
      t.integer :priority

      t.datetime :updated_at
    end
    
    add_index :token_data, :esong_key
    add_index :token_data, :token
    add_index :token_data, :priority
  end
end
