class PopulateProviders < ActiveRecord::Migration
  def self.up
    begin
      provider = Provider.new({
        :name => 'Amazon EC2',
        :long_name => 'Amazon Elastic Compute Cloud',
        :description => '',
        :main_documentation_url => 'http://aws.amazon.com/ec2/',
        :api_documentation_url => '',
        :endpoint_url => 'https://ec2.amazonaws.com/',
        :state => 'available',
        :adapter_class => 'Ec2Adapter',
      })
      provider.save!
      ProviderAccount.update_all("provider_id = #{provider.id}")
    rescue Exception => e
      puts "Got Exception attempting to populate providers:\n#{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end
  end

  def self.down
    Provider.delete_all
  end
end
