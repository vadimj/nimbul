require 's3_adapter'

class Publishers::Serverscripts < Publisher
    def description
        'Publishes server user data information to an S3 bucket.'
    end

    def initialize_parameters
        parameters = []
        parameters << PublisherParameter.new({
            :name => 's3_bucket_name',
            :control_type => 'text_field',
        })
        parameters << PublisherParameter.new({
            :name => 's3_object_name',
            :control_type => 'text_field',
        })
        return parameters
    end

    def is_configuration_good?
        account = ProviderAccount.find(self.provider_account_id, :include => [ :clusters ])
	    bucket = parameter_value('s3_bucket_name')
	    base_path = parameter_value('s3_object_name')

	    if bucket.blank? or base_path.blank?
		    self.state = "failure"
		    self.state_text = "Missing parameters bucket name and/or object name"
		    return false
	    end

        begin
	        S3Adapter.create_bucket(account, bucket)
            self.state = "success"
            self.state_text = "Successfully accessed bucket '#{bucket}'"
        rescue
            self.state = "failure"
            self.state_text = "Publisher invalid: #{$!}"
            return false
        end

        return true
    end

    def publish!
        account = ProviderAccount.find(self.provider_account_id, :include => [ :clusters ])
	    bucket = parameter_value('s3_bucket_name')
	    base_path = parameter_value('s3_object_name')

        begin
            urls = []
            intro = "# Published by UserData Publisher on "+Time.now.to_s+"\n"

		    account.clusters.each do |cluster|
				# /<cluster name>/<server name>.user_data

    			cluster_path = File.join(base_path, cluster.name)

				cluster.servers.each do |server|
					next unless server.publishable?
					server_path = File.join(cluster_path, server.name)
					
					[ :startup, :list, :reboot, :stop, :"get-hosts", :"put-hosts", :'run-server-cmd' ].each do |what|
						data = nil
						
						case what
							when :startup:
                                compress_user_data = true # false by default
								data = Server::UserDataController.generate(server, compress_user_data)
							when :'get-hosts', :'put-hosts':
								hosts_url = cluster.provider_account.get_provider_account_parameter(Publishers::Ldns::URL_PARAM_NAME)
								next if hosts_url.blank?								
						end
						
						script = Server::UserScriptController.generate(server, data, what)
						urls << (file_path = File.join(server_path, what.to_s))
						S3Adapter.put_object(account, bucket, file_path, script)
					end
				end

		    end

            update_attributes({
                :last_published_at => Time.now,
                :state => 'success',
                :state_text => urls.join('<br />')
            })
        rescue Exception => e
            update_attributes({
                :state => 'failure',
                :state_text => "Error: #{e.message}",
            })
            return false
        end

		return true
    end

    def self.label
        "Server Scripts"
    end

    protected

    def s3_url_for(bucket, path='')
        return nil if bucket.nil?
        return "http://#{bucket}.s3.amazonaws.com/#{path}"
    end

end
