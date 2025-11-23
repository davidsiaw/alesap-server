class PaselaEsongCreateTriggerJob < ApplicationJob
  queue_as :default

  def perform(id)
  	obj = PaselaEsong.find(id)


  end
end
