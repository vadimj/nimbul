#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"
ENV['DAEMON_SCRIPTLET'] = 'true'

require File.dirname(__FILE__) + "/../../config/environment"
require 'rubygems'
require 'rufus/scheduler'

# Mark all active task 'unscheduled', in case there was a crash
Task.update_all( ['is_scheduled=?', 0], { :is_active => 1, :is_scheduled => 1 } )

# Initialize the Scheduler
$scheduler = Rufus::Scheduler.start_new

$running = true
Signal.trap("TERM") do 
    # Unschedule all the tasks
    $scheduler.all_jobs.each do |job|
        job.unschedule
    end
    # Mark all active task 'unscheduled' before terminating the daemon
    Task.update_all( ['is_scheduled=?', 0], { :is_active => 1, :is_scheduled => 1 } )
    $running = false
end

while($running) do
    ActiveRecord::Base.logger.info File.basename(__FILE__).sub('.rb','')+" daemon is still running at #{Time.now}.\n"
    #Rails.logger.info File.basename(__FILE__).sub('.rb','')+" daemon is still running at #{Time.now}.\n"

    # unschedule all non-active tasks
    unschedule_tasks = Task.find_all_by_is_active_and_is_scheduled( false, true )
    unschedule_tasks.each do |t|
        $scheduler.find_by_tag(t.scheduler_tag).each do |job|
            job.unschedule
        end
        t.update_attribute( :is_scheduled, false )
        ActiveRecord::Base.logger.info "Unscheduled Server Task #{t.name} [#{t.id}]\n"
        # Rails.logger.info "Unscheduled Server Task #{t.name} [#{t.id}]\n"
    end

    # unschedule all one-time tasks with run_at in the past
    unschedule_tasks = Task.find_all_by_is_active_and_is_scheduled_and_is_repeatable( true, true, false )
    unschedule_tasks.each do |t|
        if t.run_at < Time.now.utc
            $scheduler.find_by_tag(t.scheduler_tag).each do |job|
                job.unschedule
            end
            t.update_attributes( { :is_active => false, :is_scheduled => false } )
            ActiveRecord::Base.logger.info "Unscheduled Server Task #{t.name} [#{t.id}]\n"
            # Rails.logger.info "Unscheduled Server Task #{t.name} [#{t.id}]\n"
        end
    end

    # schedule all active tasks
    schedule_tasks = Task.find_all_by_is_active_and_is_scheduled( true, false )
    schedule_tasks.each do |t|
        # make sure we haven't scheduled the task already
        if $scheduler.find_by_tag(t.scheduler_tag).length == 0
            if t.is_repeatable?
                # repeatable tasks - make sure first_at is in the future
                # otherwise scheduler will schedule all the "missed" runs
                first_at = t.run_at
                while first_at < Time.now.utc
                    first_at = first_at + Rufus.parse_time_string(t.run_every)
                end
                $scheduler.every t.run_every, :first_at => first_at, :tags => t.scheduler_tag do |job|
                    t.call(job)
                end
            else
                # non-repeatable tasks - only schedule if the run_at time is in the future
                if t.run_at > Time.now.utc
                    $scheduler.at t.run_at, :tags => t.scheduler_tag do |job|
                        t.call(job)
                    end
                end
            end
        end
        # mark the task as scheduled
        t.update_attribute( :is_scheduled, true )
        ActiveRecord::Base.logger.info "Scheduled Server Task #{t.name} [#{t.id}]\n"
        #Rails.logger.info "Scheduled Server Task #{t.name} [#{t.id}]\n"
    end

    sleep 10
end
