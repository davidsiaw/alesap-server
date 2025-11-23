class CreateIstring < ActiveRecord::Migration[5.2]
  def change
    create_table :istrings, id: :uuid do |t|

      t.string :str,
      	null: false, default: ''


      t.datetime :updated_at

    end

    add_index :istrings, :str

    add_index :istrings, :updated_at

  end
end
