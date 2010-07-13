class ResponseProcessor < ApplicationProcessor

  subscribes_to :response

  def on_message(message)
  end
end