#!/usr/bin/env ruby

LOOP_SLEEP_TIME = 60

require 'rubygems'

# You might want to change this
ENV["RAILS_ENV"] ||= "production"
ENV['DAEMON_SCRIPTLET'] = 'true'

require File.dirname(__FILE__) + "/../../config/environment"
load File.join(RAILS_ROOT, 'lib', 'detached_workers.rb')

DetachedWorkers.post_fork { ActiveRecord::Base.connection.reconnect! }
DetachedWorkers.adjust_worker_priority 15

$running = true
$manager = DetachedWorkers::Manager.instance

def shutdown
  $running = false
  $manager.shutdown!
end

Signal.trap("TERM") { shutdown }
Signal.trap("INT")  { shutdown }


while($running) do
  Rails.logger.info File.basename(__FILE__, '.rb') + " daemon is still running at #{Time.now}.\n"

  $accounts = ProviderAccount.find(:all, :select => 'id,name').select { |o| Ec2Adapter.get_ec2(o) }.collect { |o| o[:id].to_i }
  $accounts.each do |account_id|
    $manager.add_task { ProviderAccount.find_by_id(account_id).refresh }
  end
  
  $manager.complete_tasks  

  sleep LOOP_SLEEP_TIME
end
