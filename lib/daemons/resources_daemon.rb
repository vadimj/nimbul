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
    Rails.logger.info File.basename(__FILE__).sub('.rb','')+" daemon is still running at #{Time.now}.\n"

    instance_resources = InstanceResource.find_all_by_state('pending', :include => [ :instance, :cloud_resource ], :order => 'type DESC' )
    instance_resources.each do |ir|
        instance = ir.instance
        cloud_resource = ir.cloud_resource
        topic = "'#{cloud_resource.name}' #{cloud_resource.cloud_id} [#{cloud_resource.id}]"
        topic += " to #{instance.instance_id} [#{instance.id}]"
        topic += " through instance resource #{ir.id}"
        begin
            if ir.attach!
                Rails.logger.info "Successfully attached #{topic}"
            else
                Rails.logger.error "Didn't attach #{topic}: "+ir.errors.collect{ |attr,msg| attr.humanize + ': ' + msg}.join("\n\t")
            end
        rescue Exception => e
            msg = "Failed to attach #{topic}: #{e.message}"
            Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
        end
    end
  
    sleep 5
end
