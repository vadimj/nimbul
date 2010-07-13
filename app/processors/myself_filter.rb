class MyselfFilter < ActiveMessaging::Filter

  attr_accessor :options
  
  def initialize(options={})
    @options = options
  end

  def process(message, routing)
    # filter *out* messages from myself to me - this is used to prevent
    # messages from myself being sent to the 'Response' processor, which is
    # only for processing response messages coming in from the nodes
    return unless routing[:direction] == :incoming
    # Don't use the current processor if this message is from myself
    raise StopFilterException if message.headers[:sender] == routing[:destination].value.to_s
  end
end
