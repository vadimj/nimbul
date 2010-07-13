class MyselfProcessor < ApplicationProcessor

  subscribes_to :myself

  def on_message(message)
  end
end