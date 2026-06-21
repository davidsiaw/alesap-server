# frozen_string_literal: true

class CreateUserFavourites < ActiveRecord::Migration[8.1]
  def change
    create_table :user_favourites, id: :uuid do |t|
      t.string :nickname, null: false
      t.string :song_code, null: false
      t.datetime :updated_at
    end

    add_index :user_favourites, :nickname
    add_index :user_favourites, %i[nickname song_code]
  end
end
