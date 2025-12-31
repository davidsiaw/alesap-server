class CreateExtraData < ActiveRecord::Migration[8.1]
  def change
    create_table :extra_data, id: :uuid do |t|
      t.string :esong_key
      t.string :datatype
      t.string :value

      t.datetime :updated_at
    end
  end
end
