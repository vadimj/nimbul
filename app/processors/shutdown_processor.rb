class ShutdownProcessor < ApplicationProcessor

  subscribes_to :shutdown, :routing_key => 'shutdown.#'

  def on_message(message)
    logger.debug "ShutdownProcessor received: " + message
  end
end