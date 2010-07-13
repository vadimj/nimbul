class PopulateRegions < ActiveRecord::Migration
  def self.up
regions = [
[ 'eu-west-1', 'https://ec2.eu-west-1.amazonaws.com', 'Dublin, Ireland' ],
[ 'us-east-1', 'https://ec2.us-east-1.amazonaws.com', 'McLean, Virginia USA' ],
[ 'us-west-1', 'https://ec2.us-west-1.amazonaws.com', 'Bay Area, California USA' ],
]
    provider = Provider.find_by_adapter_class('Ec2Adapter')
    regions.each do |reg|
      region = provider.regions.build({ :name => reg[0], :description => reg[2], :endpoint_url => reg[1], :state => 'available', :meta_data => {} })
      region.save
    end
  end

  def self.down
    provider = Provider.find_by_adapter_class('Ec2Adapter')
    provider.regions.delete_all if provider
  end
end
