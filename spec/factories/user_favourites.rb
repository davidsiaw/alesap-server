# frozen_string_literal: true

FactoryBot.define do
  factory :user_favourite do
    nickname { "test_user" }
    song_code { "1877A6" }
  end
end
