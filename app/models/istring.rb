class Istring < ApplicationRecord
  has_paper_trail

  # str string
  validates_uniqueness_of :str
  	
end
