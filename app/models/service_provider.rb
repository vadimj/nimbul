class ServiceWithoutActiveInstance < Exception; end

class ServiceProvider < BaseModel
  belongs_to :service_type
  belongs_to :server

  has_many :service_overrides

  validates_presence_of :name, :service_type_id, :server_id
  validates_uniqueness_of :name
  
  attr_accessor :provider_account_id, :cluster_id, :server_name

  def provider_account_id
    return nil if server.nil?
    return self.server.cluster.provider_account_id
  end
  
  def cluster_id
    return nil if server.nil?
    return self.server.cluster_id
  end

  def server_name(fullname=false)
    return server.name unless !!fullname
    "#{server.service_lineage_text rescue 'Server Missing'}"
  end
  
  def type
    service_type
  end

  def overrides
    service_overrides
  end

  def fqdn
    service_type.fqdn
  end
  
  def hostline use_public_ip = false
    "%-16s\t%s" % [ (static_ip? && use_public_ip ? public_ip : private_ip), fqdn ]
  end
  
  def static_ip?
    !!CloudAddress.find_by_cloud_id(public_ip)
  end

  def instances
    server.instances
  end
  
  def active_instances
    active_instances = instances.select { |i| i.has_dns_lease? }
    raise ServiceWithoutActiveInstance unless not active_instances.empty?
    active_instances
  end
  
  def first_active_instance
    @first_active ||= active_instances.first
  end
  
  def public_ip
    begin
      first_active_instance.public_ip
    rescue ServiceWithoutActiveInstance
      '256.0.0.0'
    end
  end

  def private_ip
    begin
      first_active_instance.private_ip
    rescue ServiceWithoutActiveInstance
      '256.0.0.0'
    end
  end

  def validate
    errors.add_on_empty %w( server_id service_type_id )
  end

  named_scope :by_type, lambda {  |type|
    {
      :include => :service_type,
      :conditions => [
        'service_type_id = ?', (type.is_a?(ServiceType) ? type.id : ServiceType[type.to_s].id)
      ]
    }
  }
end
