namespace :keystore do
    desc "Reset Semaphore Lock"
    task :reset_lock => :environment do
		if not daemons_stopped?
			puts "I will *NOT* reset the lock while daemons are still running!"
			exit 1
		end
		reset_semaphore_lock RAILS_ENV || 'production'
    end

    def daemons
        Dir[File.dirname(__FILE__) + "/../daemons/*_ctl"]
    end
	
	def daemons_stopped?
		stopped = true
		daemons.each do |d|
			# in the expression below, false indicates that a daemon
			# does have a pid which means it is running
			result = !!(`#{d} status` !~ /\[pid [0-9]+\]/) 
			stopped = stopped & result
		end
		return stopped
	end

	def reset_semaphore_lock(env = 'production')
		load File.dirname(__FILE__) + '/../transient_key_store.rb'
		env_token = 'TransientKeyStore:' + env
		sm_data_key = ftok('/dev/random', TransientKeyStore.crc16(env_token + ':data'))
		semaphore  = Semaphore.new(sm_data_key, TransientKeyStore::SEMSET_MAX, IPC_CREAT | 0666)
    semaphore.remove
		puts "Lock reset for #{env_token}"
	end
end
