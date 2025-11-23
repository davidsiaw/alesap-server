class CommandCreateTriggerJob < ApplicationJob
  queue_as :default

  def perform(id)
  	obj = Command.find(id)


  end
end
