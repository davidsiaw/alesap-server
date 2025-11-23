class PaselaArtist < ApplicationRecord
  has_paper_trail
    # master_singer_id string
    validates_uniqueness_of :master_singer_id
    
    # artist_name_id is a istring
    ulid :artist_name_id
    belongs_to :artist_name, class_name: "Istring", foreign_key: :artist_name_id

end
