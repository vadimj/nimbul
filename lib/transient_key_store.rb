#
# Class for transient storage of sensitive keys in Shared Memory
#

# author: Carl P. Corliss
# version: 1.0
# $Id$
# CopyRight: The New York Times

require 'sysvipc'
require 'singleton'

include SystemVIPC

class TransientKeyStore
  # number of semaphores in set (2 right now, locker and version)
  # increase if more are added
  SEMSET_MAX  = 0x02

  # Semaphore Set Indexes
  SEMSET_LOCKER_IDX  = 0x00
  SEMSET_VERSION_IDX = 0x01

  private_class_method :new

  @@instances = {}

  attr_reader :version
  
  def self.instance(env = 'production')
    if not @@instances.has_key?(env.to_s.downcase)
      @@instances[env] = new(env)
    end
    @@instances[env]
  end

   def initialize(env = 'production')
    @env = env
    @env_token = 'TransientKeyStore:' + env if @env_token.nil? # only set it once per instance!
    
    @locked    = false
    @data      = {}
    @version   = 1
    
    # make sure to unlock if we're locked
    at_exit { unlock if @locked }
    
    setup_data
    setup_semaphores
    load
   end
   
  def setup_data
    @sm_data_key = ftok('/dev/random', TransientKeyStore.crc16(@env_token + ':data'))
    @sm_size_key = ftok('/dev/random', TransientKeyStore.crc16(@env_token + ':data_size'))

    # store the size of the data in a seperate shared memory segment, only
    # four bytes long (native unsigned long integer)
    # FIXME: short integer (typically, 65K) is likely big enough
    @sm_size = SharedMemory.new(@sm_size_key, 4, IPC_CREAT | 0666)
    @sm_size.attach

    @sm_data = SharedMemory.new(@sm_data_key, memory_size(), IPC_CREAT | 0666)
    @sm_data.attach
  end

  def setup_semaphores
    @semaphore = Semaphore.new(@sm_data_key, 2, IPC_CREAT | 0666)
    if @semaphore.pid(0) == 0
      @semaphore.set_value(SEMSET_LOCKER_IDX,  1)
      @semaphore.set_value(SEMSET_VERSION_IDX, 1)
    end
    @version = stored_version
  end

  def destroy
    lock; begin
      @sm_data.detach
      @sm_data.remove

      @sm_size.detach
      @sm_size.remove

      @data = {}
      @sm_data = @sm_size = nil

      # remove the semaphore only /after/ we're done
      # destroying everything else
      @semaphore.remove
      @semaphore = nil
    end
  end

  def data_key() @sm_data_key; end
  def size_key() @sm_size_key; end

  def key(k) return get(k); end
  def keys() @data.keys; end

  def [](k) return get(k); end
  def []=(k,v) return set(k,v); end

  def marshall_size()
    Marshal.dump(@data).length
  end

  def memory_size()
    size = @sm_size.read(4).unpack('L')[0]
    size > 0 ? size : 4 # default to four bytes (the size of a marshalled hash)
  end

  def get(key)
    # always use the most up to date values
    load { @data[key] rescue nil }
  end

  def set(key, value)
    store { @data[key] = value }
    value
  end

  def delete(key)
    return if not @data.has_key?(key)
    old_value = @data[key]
    store { @data.delete(key); }
    old_value
  end

  def clear
    old_keys = @data
    keys.each { |k| delete(k) }
    old_keys
  end

  def length() @data.length; end

  def locked?() !!@locked; end

  def version_updated?
    !!(@version != stored_version)
  end

  def stored_version
    @semaphore.value(SEMSET_VERSION_IDX)
  end
  
  def increment_version
    @semaphore.apply([SemaphoreOperation.new(SEMSET_VERSION_IDX, 1)])
    reload
  end
  
  def lock()
    begin
      # we subtract one, bringing the counter to zero which
      # causes other processes attempting to do the same to block
      @semaphore.apply([SemaphoreOperation.new(SEMSET_LOCKER_IDX, -1)])
      @locked = true
    rescue Exception => e
      # oddly, I can't catch Errno::EINVAL or SystemVIPC::Error
      # (maybe due to some rails issue) so we have to kludge it

      # raise up if it's not a system vipc type of error
      raise e if (e.class.to_s.downcase !~ /^(errno::(einval|eidrm)|systemvipc::error)/)

      # semaphore was removed - likely caused by someone calling destroy
      setup_semaphores
      retry
    end
  end

  def unlock()
    begin
      # increment to > 0 means that it is no longer blocking
      @semaphore.apply([SemaphoreOperation.new(SEMSET_LOCKER_IDX, 1)]);
      @locked = false
    rescue Exception => e
      # oddly, I can't catch Errno::EINVAL or SystemVIPC::Error
      # (maybe due to some rails issue) so we have to kludge it

      # raise up if it's not a system vipc type of error
      raise e if (e.class.to_s.downcase !~ /^(errno::(einval|eidrm)|systemvipc::error)/)

      # semaphore was removed - likely caused by someone calling destroy
      setup_semaphores
      retry
    end
  end

  def reload()
    return self unless version_updated?
    # this is destructive /only/ for this thread
    # so there is no reason to lock it
    
    # now detach everything so we don't leak memory
    @sm_data.detach
    @sm_size.detach
    
    # and nil it all out
    @sm_data = @sm_size = nil
    @data = {}
    
    setup_data
    setup_semaphores
    
    load
    self
  end

private

  def load
    @data = Marshal.load(@sm_data.read(memory_size())) rescue {}
    return yield if block_given?
  end

  def store
    lock; begin
      yield if block_given?

      # detach and remove the old segment
      @sm_data.detach
      @sm_data.remove

      # now recreate it with the new size
      @sm_data = SharedMemory.new(@sm_data_key, marshall_size(), IPC_CREAT | 0666)
      @sm_data.attach

      # and now write the data
      @sm_data.write(Marshal.dump(@data))

      store_memory_size()
      
      # increment our semaphore counter representing the current version
      increment_version
    rescue Exception => e
      # oddly, I can't catch Errno::EINVAL or SystemVIPC::Error
      # (maybe due to some rails issue) so we have to kludge it

      # raise up if it's not a system vipc type of error
      raise e if (e.class.to_s.downcase !~ /^(errno::(einval|eidrm)|systemvipc::error)/)

      # lost our shared memory pool (possible destroy?)
      unlock; @data = {}; restart; lock
      retry
    ensure unlock; end
  end

  def store_memory_size
    # lastly, update the stored size
    # XXX: this should /only/ be called from inside of
    # a semaphore locked block
    @sm_size.write([marshall_size()].pack('L'))
  end

  def self.crc16(c)
    r = 0xFFFF
    c.each_byte do |b|
      r ^= b
      8.times do
        r = (r>>1) ^ (0xEDB8 * (r & 1))
      end
    end
    r ^ 0xFFFF
  end
end
