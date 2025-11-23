class PaselaEsong < ApplicationRecord
  has_paper_trail

    # esong_key string
    validates_uniqueness_of :esong_key

    # name_id is a istring
    ulid :name_id
    belongs_to :name, class_name: "Istring", foreign_key: :name_id

    # ruby_id is a istring
    ulid :ruby_id
    belongs_to :ruby, class_name: "Istring", foreign_key: :ruby_id

    delegate :song_name, to: :name
end
