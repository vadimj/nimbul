#!/usr/bin/env ruby

LOOP_SLEEP_TIME = 1.0

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
	# move each operation in proceed state to it's next step
	# and handle operations that need to timeout
	
  Operation.find_all_by_state(:proceed).each do |operation|
    $manager.add_task { operation.step! }
  end

	Operation.find_all_by_state(:waiting, :conditions => [ 'timeout_at <= ?', Time.zone.now ]).each do |operation| 
    $manager.add_task { operation.reentrant_timeout! }
	end

  $manager.complete_tasks
  
	sleep LOOP_SLEEP_TIME
end

