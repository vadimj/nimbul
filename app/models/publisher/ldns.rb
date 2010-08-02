require 's3_adapter'

class Publisher::Ldns < Publisher
  URL_PARAM_NAME = 'HOSTS_FILE_URL'
  
  before_destroy :remove_url_parameter
  
  def description
    'Publishes a per cluster DNS host file to an S3 bucket. Updates the provider account adding the (readonly) environment variable HOSTS_FILE_URL containing the URL of the published file.'
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
    account = ProviderAccount.find(self.provider_account_id, :include => { :clusters => :servers } )
    bucket = parameter_value('s3_bucket_name')
    base_path = parameter_value('s3_object_name')

    begin
      urls = []
      intro = "# Published by DNS Publisher on "+Time.now.to_s+"\n"

      hosts_hash = DNS_Adapter.as_hash(provider_account)
      hostfile = intro + DNS_Adapter.render_as_hosts_file(hosts_hash).join
      jsonfile = hosts_hash.to_json
      
      # example: .../provider-1.hosts
      provider_path = File.join(base_path, "provider-#{account.id.to_s}.hosts")
      S3Adapter.put_object(account, bucket, provider_path, hostfile, 'public-read')
      urls << provider_path
      
      provider_json = File.join base_path, "provider-#{account.id.to_s}.json"
      S3Adapter.put_object(account, bucket, provider_json, jsonfile, 'public-read')
      urls << provider_json

      account.clusters.each do |cluster|
        # example: /provider-1/cluster-1.hosts
        cluster_path = File.join(provider_path, "cluster-#{cluster.id.to_s}.hosts")
        S3Adapter.put_object(account, bucket, cluster_path, hostfile, 'public-read')
        urls << cluster_path
      end

      urls.collect!{ |p| "<a href='#{s3_url_for(bucket,p)}' target=_new>#{s3_url_for(bucket,p)}</a>" }
      account.set_provider_account_parameter(URL_PARAM_NAME , s3_url_for(bucket, provider_path), true)
        
      update_attributes({
        :last_published_at => Time.now,
        :state => 'success',
        :state_text => urls.join('<br />')
      })
    rescue
      update_attributes({
        :state => 'failure',
        :state_text => "Error: #{$!}",
      })
      return false
    end

    return true
  end

  def self.label
    "LDNS"
  end

  protected

  def s3_url_for(bucket, path='')
    return nil if bucket.nil?
    return "http://#{bucket}.s3.amazonaws.com/#{path}"
  end

  def remove_url_parameter
    param = ProviderAccount.find(self.provider_account_id).provider_account_parameters.detect { |p| p.name == URL_PARAM_NAME }
    param.destroy unless param.nil?
  end
end
