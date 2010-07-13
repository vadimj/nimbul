class StartupProcessor < ApplicationProcessor

  subscribes_to :startup, :routing_key => 'startup.#'

  def on_message(msg)
    name, public_ip, local_ip, instance_id, server_id = message.args
    
    return unless request_valid? server_id

    # find an existing instance or create a new one if it doesn't exist
    instance = account.instances.detect do |i|
      i.instance_id == instance_id
    end || account.instances.build({ :instance_id => instance_id })

    # populate instance's server_id if it's not set already
    # we don't allow instances to migrate from server to server yet :)
    if instance.server_id.nil? or instance.server_id == 0
      instance.server_id = server_id
      instance.server_name = server.nil? ? 'Unknown' : server.name
      instance.save
    end

    # Add initialization operation to the instance	
    instance.operations << (
      @operation = Operation.factory(
        'Operations::Initialization',
        :args => {
          :local_ip => local_ip,
          :public_ip => public_ip
        }
      )
    )

    stored_message.operation_id = @operation.id
    stored_message.save

    @operation.step!
  end
  
  private
  
  def request_valid? server_id

    # check to make sure server_id is specified
    if server_id.nil?
      text = "Initialization Request from instance [#{instance_id}] is missing server_id value. " +
             "It is likely not set correctly in the instance's /etc/cloudrc file"
      puts text
      Rails.logger.error text
      stored_message.message = text
      stored_message.state = 'error'
      stored_message.save
      return false
    end
    
    # check to make sure server exists
    server = Server.find(server_id)
    if server.nil?
      text = "Initialization Request from instance [#{instance_id}] specifies a server_id [#{server_id}] for server that doesn't exist"
      puts text
      Rails.logger.error text
      stored_message.message = text
      stored_message.state = 'error'
      stored_message.save
      return false
    end
    
    # check to make sure the server belongs to this account
    if Cluster.find_by_provider_account_id_and_id(account.id, server.cluster_id).nil?
      text = "Initialization Request from instance [#{instance_id}] specifies a server_id [#{server_id}] for server that doesn't belong to '#{account.name}' [#{account.id}]"
      puts text
      Rails.logger.error text
      stored_message.message = text
      stored_message.state = 'error'
      stored_message.save
      return false
    end
    
    true
  end
end