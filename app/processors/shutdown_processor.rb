class ShutdownProcessor < ApplicationProcessor

  subscribes_to :shutdown, :routing_key => 'shutdown.#'

  def on_message(msg)
    server_id, cluster_id, account_id, cloud_id = message.args
    
    instance = Instance.find_by_instance_id_and_server_id(instance_id, server_id)
    return unless instance and instance.running? and instance.ready?
    instance.disable!
  end
end