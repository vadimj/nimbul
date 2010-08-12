module Behaviors::Operating
  module InstanceBehaviors
    def task_verify_message
      ''
    end
    
    def timeout_exceeded?()
      return ( not self[:timeout_at].nil? && Time.at(self[:timeout_at]) <= Time.now )
    end

    def max_attempts_exceeded?()
      return self[:attempts] >= max_attempts
    end

    def get_message_responses
      msgs = InMessage.find_by_sender_and_operation_id(instance.instance_id, self[:id])
      msgs.inject({}) do |h,m|
        data = (YAML.load(m[:data]) rescue m[:data])
        h[m.handler] = m[:data]
        h
      end
      return msgs
    end

    def get_response_by_handler(handler_name)
      InMessage.find_by_sender_and_operation_id_and_handler(
        instance.instance_id,
        self[:id],
        handler_name,
        :order => 'id DESC'
      )
    end

    def next_attempt!
      self[:attempts] += 1
      if max_attempts_exceeded?
        return fail!
      end
      proceed!
    end

    def can_succeed?
      is_last_step? and not failed? and not succeeded? and not waiting?
    end
        
    def step!
      return succeed! if can_succeed?
      return true unless proceed?
      
      timeout_reset && wait!
      next_step!.execute

    rescue Exception => e
      bt_sample = e.backtrace
      unless e.backtrace.size <= 10
        # show only the first five, and last five
        bt_sample = bt_sample[0,5] + [ " ... #{bt_sample.size - 10} more ..." ] + bt_sample[-5,5]
      end
      
      self[:result_code]    = 'Error_StepExecutionFailure'
      self[:result_message] = "#{e.class.name}: #{e.message}\n\t#{bt_sample.join("\n\t")}"
      fail!

      self.update_attribute(:current_step, (self.current_step - 1))

      Rails.logger.error "Operation Error: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      raise e
    end

  protected
    def is_last_step?() self.current_step >= (steps.length - 1); end

    def next_step(); return steps[self.current_step+1]; end
    def prev_step(); return steps[self.current_step-2]; end

    def next_step!
      self.update_attribute(:current_step, self.current_step + 1)
      return steps[self.current_step]
    end

    def prev_step!
      self.update_attribute(:current_step, self.current_step - 2) if self.current_step > 0
      return steps[self.current_step]
    end

    def repeat_this_step!
      self.update_attribute(:current_step, self.current_step - 1)
      proceed!
    end

    def instance_request_path instance
      "#{server_request_path instance}.#{instance.instance_id}"
    end
    
    def server_request_path instance_or_server
      case instance_or_server
        when Server
          "#{cluster_request_path instance_or_server}.#{instance_or_server.id}"
        when Instance
          "#{cluster_request_path instance_or_server}.#{instance_or_server.server.id}"
      else
        raise ArgumentError, "argument must be an instance or server!"
      end
    end
    
    def cluster_request_path instance_server_or_cluster
      name = case instance_server_or_cluster
        when Cluster
          instance_server_or_cluster.id
        when Server
          instance_server_or_cluster.cluster.id
        when Instance
          instance_server_or_cluster.server.cluster.id
      else
        raise ArgumentError, "argument must be an instance, server or cluster!"
      end
      
      "request.#{account.id}.#{name}"
    end

    def send_control_command agent, method, args = [], headers = {}
      send_message :control, 'control', agent, method, args, headers
    end
    
    def send_rabbitmq_command method, args = [], headers = {}
      send_message :rabbitmq, 'rabbitmq', :rabbitmq, method, args, headers
    end
    
    def send_request(destination, agent, method, args = [], headers = {})
      send_message :request, destination, agent, method, args, headers
    end

    def send_message(destination, routing_key, agent, method, args = [], headers = {})
      puts "Sending #{agent}:#{method} request to #{destination} with routing key '#{routing_key}'"
      publish(
        destination,
        { :account => account.id, :agent => agent, :method => method, :args => args },
        headers.merge({
          :routing_key => routing_key.to_s,
          :recipient   => routing_key.to_s,
          :replyto     => 'nimbul',
          :operation   => self.id
        })
      )
    end
  end
end
