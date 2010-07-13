class ResponseFilter < ActiveMessaging::Filter

  attr_accessor :options
  
  def initialize(options={})
    @options = options
  end

  def process(message, routing)
    # filter *out* messages from nodes to me - this is used to prevent
    # response messages being sent to the 'Myself' processor, which is
    # only for processing internal Nimbul messages
    return unless routing[:direction] == :incoming
    # Don't use the current processor if this message is from a node
    raise StopFilterException if message.headers[:sender] != routing[:destination].value.to_s
  end
end
