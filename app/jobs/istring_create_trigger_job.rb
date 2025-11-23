class IstringCreateTriggerJob < ApplicationJob
  queue_as :default

  def perform(id)
  	obj = Istring.find(id)


  end
end
