class CreateCommand < ActiveRecord::Migration[5.2]
  def change
    create_table :commands, id: :uuid do |t|

      t.string :verb,
      	null: false, default: ''
      t.string :subject,
      	null: false, default: ''
      t.integer :amount,
      	null: false, default: ''


      t.datetime :updated_at

    end

    add_index :commands, :verb
    add_index :commands, :subject
    add_index :commands, :amount

    add_index :commands, :updated_at

  end
end
