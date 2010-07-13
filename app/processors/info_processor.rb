class InfoProcessor < ApplicationProcessor

  subscribes_to :info, :routing_key => 'info.#'

  def on_message(message)
    super(message)
  end
end