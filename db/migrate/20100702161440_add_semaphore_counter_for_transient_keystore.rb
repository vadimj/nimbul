class AddSemaphoreCounterForTransientKeystore < ActiveRecord::Migration
  def self.up
    load File.join(RAILS_ROOT, 'lib', 'transient_key_store.rb')
    [ :production, :development, :testing ].each do |env|      
      env_token = 'TransientKeyStore:' + env.to_s
      sm_data_key = ftok('/dev/random', TransientKeyStore.crc16(env_token + ':data'))
      semaphore  = Semaphore.new(sm_data_key, 1, IPC_CREAT | 0666)
      semaphore.remove
    end
  end

  def self.down
    # nothing to do - no need to downgrade, though not really an Irreversible migration
  end
end
