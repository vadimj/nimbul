#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"
ENV['DAEMON_SCRIPTLET'] = 'true'

require File.dirname(__FILE__) + "/../../config/environment"

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do

    # Replace this with your code
    Rails.logger.info File.basename(__FILE__).sub('.rb','')+" daemon is still running at #{Time.now}.\n"

    # process any dns acquire/release requests
	DnsRequest.process_requests
	sleep 1
end
