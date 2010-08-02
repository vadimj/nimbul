class Publisher::Nagios < Publisher
    def description
        'Publishes list of instances with DNS information and roles.'
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
            intro = "# Published by Nagios Publisher on "+Time.now.to_s+"\n"
            options = {
                :skip_static_dns => true,
                :include_server_info => true,
            }

            # collect entries including roles but skip all the down instances
            host_entries = DNS_Adapter.get_host_entries(provider_account, options)
            host_entries.collect!{ |e| e if e !~ /isdown/ }.compact!

            hostfile = intro + host_entries.join
            S3Adapter.put_object(account, bucket, base_path, hostfile, 'public-read')

            urls << base_path
            urls.collect!{ |p| "<a href='#{s3_url_for(bucket,p)}' target=_new>#{s3_url_for(bucket,p)}</a>" }
            
            update_attributes({
                :last_published_at => Time.now,
                :state => 'success',
                :state_text => urls.join('<br />')
            })
        rescue
            update_attributes({
                :state => 'failed',
                :state_text => "Error: #{$!}",
            })
            return false
        end

    return true
    end

    def self.label
        "Nagios"
    end

    protected

    def s3_url_for(bucket, path='')
        return nil if bucket.nil?
        return "http://#{bucket}.s3.amazonaws.com/#{path}"
    end
end
