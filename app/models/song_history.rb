# frozen_string_literal: true

class SongHistory < ApplicationRecord
  validates :nickname, presence: true, length: { maximum: 100 }
  validates :song_code, presence: true, length: { maximum: 20 }
end
