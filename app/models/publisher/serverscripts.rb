require 's3_adapter'

class Publisher::Serverscripts < Publisher
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
    account = ProviderAccount.find(
      self.provider_account_id,
      :include => { :clusters => { :servers => :server_profile_revision }}
    )
    
    server_images = ServerImage.all(
      :joins => [
        'INNER JOIN server_profile_revisions AS spr ON server_images.image_id = spr.image_id',
        'INNER JOIN servers ON spr.id = servers.server_profile_revision_id',
        'INNER JOIN clusters ON servers.cluster_id = clusters.id'
      ],
      :conditions => { :clusters => { :id => account.clusters.collect { |c| c[:id] }}}
    ).inject({}) do |h,si|
      h[si[:image_id]] = si[:location]; h
    end

    bucket = parameter_value('s3_bucket_name')
    base_path = parameter_value('s3_object_name')
    
    begin
      urls = []
      
      account.clusters.each do |cluster|
        # /<cluster name>/<server name>.user_data
        cluster_path = File.join(base_path, cluster.name)

        cluster.servers.each do |server|
          next unless server.startable? and not server_images[server.image_id].nil?
          file_path = File.join(cluster_path, server.name, 'server-control')

          script = Server::UserScriptController.generate(server, true)
          S3Adapter.put_object(account, bucket, file_path, script)
          urls << script_popup(server, file_path)
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
        :state_text => "Error: <pre>#{e.message}\n\t#{e.backtrace.join("\n\t")}</pre>",
      })
      return false
    end

    return true
  end

  def self.label
    "Server Scripts"
  end

  protected

    def script_popup(server, filepath)
      url = "/server/#{server[:id]}/user_script"
      popup_options = "this.href, 'server_server_user_script_#{server[:id]}', 'height=640,width=760'"
      return %Q[<a href="#{url}" onclick="window.open(#{popup_options}); return false;">#{filepath}</a><br />]
    end
end
