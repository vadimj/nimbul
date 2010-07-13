require 'activemessaging/message_sender'

module Behaviors::EventPublisher
  module InstanceBehaviors
    include ActiveMessaging::MessageSender
  end
end
