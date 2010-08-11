require 'operation/rabbit_mq'
class Operation::RabbitMq::ChangePassword < Operation::RabbitMq
	USERDATA_PATH = File.join(RAILS_ROOT, 'app', 'views', 'server', 'user_data')

	def steps
    steps = super
    
    steps << Operation::Step.new('change_password') do
    
      timeout_in(5.minutes)
  
      provider_account = ProviderAccount.find(self[:args][:provider_account_id])    
      send_rabbitmq_command :change_password, [ 
        provider_account.messaging_username,
        provider_account.messaging_password
      ]
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = "Request to change messaging user password for account '#{provider_account.name}'"
    
      operation_logs << OperationLog.new( {
        :step_name => 'change_password',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )

      unless success
        fail! && next
      end
      proceed! if not failed?
    end
    
    steps << Operation::Step.new('update_configurations') do
			timeout_in(5.minutes)
			
			instances = Instance.all(
				:conditions => { :provider_accounts => {:id => self[:args][:provider_account_id]} },
				:joins => [
					'INNER JOIN servers ON instances.server_id = servers.id',
					'INNER JOIN clusters ON servers.cluster_id = clusters.id',
					'INNER JOIN provider_accounts ON clusters.provider_account_id = provider_accounts.id'
				]				
			)
			
			unless instances.empty?
				results = update_configuration instances
				errors = :none
				if results.values.any? { |r| !!r.match(/ERROR/) }
					errors = :partial
					errors = unless results.values.all? {|r| !!r.match(/ERROR/) }; :all else; :partial; end
				end
				success = (errors == :none)
				self[:result_code] = success ? 'Success' : (errros == :partial ? 'Partial Failure' : 'Failure')
				self[:result_message] = results.map { |id,result| "<div><h2>#{id}:</h2>#{results}<div>" }.join "<br />\n<hr>"
			else
				success = true
				self[:result_code] = success ? 'Success' : 'Failure'
				self[:result_message] = 'No active instances to update.'
			end
			
			operation_logs << OperationLog.new( {
				:step_name => 'update_configurations',
				:is_success => success,
				:result_code => self[:result_code],
				:result_message => self[:result_message],
			})

      unless success
        fail! && next
      end
      proceed! if not failed?
    end
    
    return steps
	end

private

	def with_command_file(commands, requested_binding)
		raise ArgumentError, 'Missing block!' unless block_given?
		f = Tempfile.new('.tmp-io-')
		begin
			f.chmod 0750 
			f.write <<-EOF
	#!/usr/bin/env bash
	
	# make sure to remove this file when we're done
	trap 'rm -f $0; trap - EXIT; exit' EXIT
	
			EOF
			
			f.write ERB.new(commands, nil, '%-').result(requested_binding)
			f.flush
			yield f.path
		ensure
			f.close!
		end
	end
	
	def update_configuration instances
		instances.inject({}) do |results, instance|
			begin
				@instance = instance
				@provider_account = @instance.provider_account
				@server = @instance.server
				@cluster = @server.try(:cluster)
				
				commands = <<-EOS
emissary stop

# configure emissary
mkdir -p /etc/emissary
cat << 'EOF' > /etc/emissary/config.ini
<%= ERB.new(IO.read(File.join(USERDATA_PATH, 'emissary.erb')), nil, '%-').result(binding) %>
EOF

# restart emissary with the updated events configuration
emissary start -d

exit 0
				EOS
				
				id = instance[:instance_id]

				with_command_file(commands, binding) do |command_file_path|
					filename = File.basename(command_file_path)
					@provider_account.with_ssh_master_key do |keyfile|
						@instance.send_file(command_file_path, filename, :keyfile => keyfile)
						Timeout.timeout(60) do 
							results[id] = @instance.ssh_execute("./#{filename}; rm -f ./#{filename}", :keyfile => keyfile)
						end
					end
				end
			rescue Timeout::Error
				results[id] = 'ERROR: timed out...'
			rescue Net::SSH::AuthenticationFailed
				results[id] = 'ERROR: authentication failed...'
			rescue Errno::EHOSTUNREACH
				results[id] = 'ERROR: host unreachable...'
			rescue Exception => e
				results[id] = "ERROR: #{e.class.name}: #{e.message} (for full details, see logs)"
				Rails.logger.error "#{e.class.name}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
			end
		end
	end
end
