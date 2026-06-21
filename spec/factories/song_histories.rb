# frozen_string_literal: true

FactoryBot.define do
  factory :song_history do
    nickname { "test_user" }
    song_code { "1943B8" }
    last_played_at { 1748131200 }
  end
end
