#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../../config/environment"

$: << File.join(RAILS_ROOT, 'vendor', 'plugins', 'activemessaging', 'lib')
require 'activemessaging'

# You might want to change this
ENV["RAILS_ENV"] ||= "production"
ENV['DAEMON_SCRIPTLET'] = 'true'

$running = true
Signal.trap("TERM") do 
  $running = false
end

ActiveMessaging::start
