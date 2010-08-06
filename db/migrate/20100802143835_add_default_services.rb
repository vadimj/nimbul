class AddDefaultServices < ActiveRecord::Migration
  def self.up
    ServiceType.create(:name => 'EVENTS', :fqdn => 'events.mydomain.com', :description => 'Event Messaging Service').save(false)
    ServiceType.create(:name => 'SVN', :fqdn => 'svn.mydomain.com', :description => 'Subversion Service').save(false)
  end

  def self.down
  end
end
