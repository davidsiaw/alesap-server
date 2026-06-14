# frozen_string_literal: true

FactoryBot.define do
  factory :song_history do
    nickname { "test_user" }
    song_code { "1943B8" }
    last_played_date { "2026/6/13" }
    last_played_time { "17:45:51" }
  end
end
