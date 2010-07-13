# Class holding daemon info
class Daemon
	attr_accessor :id, :name, :pid, :state, :started_at, :last_ran_at

	def initialize(name)
        @id = name
		@name = name
        @pid = get_pid 
		@state = get_state
		@started_at = get_started_at
        @last_ran_at = get_last_ran_at
	end

    def id
        name
    end

    def get_pid
        id = nil
        begin
            unless self.pid_file.nil?
                f = File.open(self.pid_file)
                a = f.readlines
                id = a[0].to_i unless a.nil? or a.size == 0
            end
        rescue
            Rails.logger.error "Failed to determine the pid of a daemon #{name}: #{$!}"
        end
        id
    end

    def get_state
        s = 'stopped'
        return s if self.pid.nil?
        begin
            s = 'running' if (Process.kill 0, self.pid) == 1
        rescue
            Rails.logger.error "Failed to determine the state of a daemon #{name}: #{$!}"
        end

        return s
    end

    # started at time as determines by mtime on the pid file
    def get_started_at
        return nil if self.pid_file.nil?
        File.mtime(self.pid_file)
    end

    # last ran time as determined by mtime on the log file
    def get_last_ran_at
        return nil if self.log_file.nil?
        File.mtime(self.log_file)
    end

    def call_ctl_command(command, options = {})
        options[:rails_env] = Rails.env
        args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
        system "#{args.join(' ')} #{ctl_file} #{command} >> #{Rails.root}/log/daemons_ctl.log &"
    end

    def start!(options = {})
        call_ctl_command(:start, options)
    end

    def stop!(options = {})
        call_ctl_command(:stop, options)
    end

    def restart!(options = {})
        call_ctl_command(:restart, options)
    end

    # class methods

    # if we ever make daemons active records - remove the finder methods
    def self.find(*args)
        options = args.extract_options!
        case args.first
            when :all then  find_every(options)
            else            find_from_ids(args.first, options)
        end
    end

    def self.find_every(options)
        Dir["#{Rails.root}/lib/daemons/*_ctl"].collect{|f| File.basename(f).sub('_ctl','')}.sort{|a,b| a <=> b}.collect{|f| Daemon.new(f)}
    end

    def self.find_from_ids(ids, options)
        if ids.kind_of?(Array)
            find_some(ids, options)
        else
            find_one(ids, options)
        end
    end

    def self.find_one(id, options)
        Dir["#{Rails.root}/lib/daemons/#{id}_ctl"].collect{|f| File.basename(f).sub('_ctl','')}.collect{|f| Daemon.new(f)}.first
    end

    def self.find_some(ids, options)
        daemons = []
        ids.each do |id|
            daemons << find_one(id, options)
        end
        daemons
    end

    def self.count
        find(:all).size
    end

    # utility methods

    def pid_file
        Dir["#{Rails.root}/log/#{name}.rb_monitor.pid"].first
    end

    def log_file
        Dir["#{Rails.root}/log/#{name}.rb.log"].first
    end

    def ctl_file
        Dir["#{Rails.root}/lib/daemons/#{name}_ctl"].first
    end

end
