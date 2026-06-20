# frozen_string_literal: true

class SongCounter < ApplicationRecord
  validates :nickname, presence: true, length: { maximum: 100 }
  validates :song_code, presence: true, length: { maximum: 20 }
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :song_code, uniqueness: { scope: :nickname }
end
