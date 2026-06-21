# frozen_string_literal: true

class UserFavourite < ApplicationRecord
  validates :nickname, presence: true, length: { maximum: 100 }
  validates :song_code, presence: true, length: { maximum: 20 }
  validates :song_code, uniqueness: { scope: :nickname }
end
