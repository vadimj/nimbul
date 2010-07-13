
require 'rubygems'
require 'singleton'
require 'work_queue'

load File.join(File.dirname(File.expand_path(__FILE__)), 'facter_fixes.rb')

module DetachedWorkers

  class Task
    attr_reader :args
    def initialize *args, &block
      @block = block
      @args  = *args
    end
    
    def execute
      @block.call(*@args)
    end
  end

  
  class Worker
    attr_accessor :pid
    attr_reader :tasks
    def initialize
      @pid   = nil
      @tasks = []
      @work_queue = WorkQueue.new(10, nil, 60) # Maximum of ten worker threads per worker process
    end
    
    def perform_tasks
      return unless @tasks.size > 0
      
      DetachedWorkers.worker_pre_fork.execute

      # return to parent after fork, unless we're in the child
      return @pid unless (@pid = fork).nil?

      Signal.trap("TERM") { @work_queue.stop; exit! }
      Signal.trap("INT") { @work_queue.stop; exit! }

      DetachedWorkers.worker_post_fork.execute

      Process.setpriority(Process::PRIO_PROCESS, 0, DetachedWorkers.worker_priority)
      
      @pid = $$
      $0 = '__worker__'
      
      @tasks.each do |task|
        @work_queue.enqueue_b {
          puts "Executing Task in worker[#{@pid}] with args: #{task.args.inspect}" if DetachedWorkers.debug?
          task.execute
          puts "Finished Task in worker[#{@pid}]  with args: #{task.args.inspect}" if DetachedWorkers.debug?
        }
      end
      
      @work_queue.join
      
      # once the tasks are finished, exit!
      # note: we MUST exit our child with exit! or
      # we'll end up call our "at_exit" above..
      exit! 
    end
    
    def clear_tasks
      @tasks = []
    end
  end
  
  class Manager
    include ::Singleton
    
    MAX_WORKERS = Facter.processor_count + 1
    
    attr_reader :workers
    def initialize
      at_exit { shutdown }
      @workers = (1..MAX_WORKERS).to_a.collect { Worker.new }
    end
  
    def add_task *args
      raise ArgumentError, "Missing required task block!" unless block_given?
      get_available_worker.tasks << Task.new(*args) { |*block_args| yield(*block_args) } 
    end
  
    def complete_tasks
      DetachedWorkers.manager_pre_fork.execute
      @workers.each { |w| w.perform_tasks }
      DetachedWorkers.manager_post_fork.execute

      wait_until_complete!
      @workers.each { |w| w.clear_tasks } unless DetachedWorkers.keep_tasks?
    end
    
    def shutdown!
      @workers.each { |worker| terminate! worker.pid  unless worker.pid.nil? }
    end

    private

    def wait_until_complete!
      while @workers.any? { |w| not w.pid.nil? } do
        @workers.select{ |w| w.pid }.each do |w|
          reaped = false
          reaped |= !!Process.waitpid(w.pid, Process::WNOHANG) unless w.pid.nil?
          w.pid = nil if reaped
        end
        sleep 1.5 # take a break between reaping
      end
    end
      
    def get_available_worker
      @workers.sort{|a,b| a.tasks.size <=> b.tasks.size}.first
    end
    
    def terminate! worker_id
      Process.kill('TERM', worker_id) unless worker_id.nil?
    end
    
  end

  NOOP = Task.new do; end

  class << self
    @@debug = false
    @@worker_priority = 5
    @@keep_tasks = false
    @@hooks = {
      :manager => {
        :pre  => NOOP,
        :post => NOOP,
      },
      :worker => {
        :pre  => NOOP,
        :post => NOOP,
      }
    }
    
    def debug=(v)
      @@debug = !!v
    end
    
    def debug?
      @@debug
    end

    # higher numbers for higher priority
    def adjust_worker_priority priority = 5
      # Force the refresh to have a low scheduling priority
      #(higher number == lower priority)
      @@worker_priority = Integer(priority)
    end
    
    def worker_priority
      @@worker_priority || 5
    end
    
    def set_keep_tasks=(v)
      @@keep_tasks = !!v
    end
    
    def keep_tasks?
      !!@@keep_tasks
    end
    
    def pre_fork(*args)
      [:manager, :worker].each do |who|
        set_code_hook(who, :pre, *args) { |*largs| yield(*largs) }
      end
    end
    
    def post_fork(*args)
      [:manager, :worker].each do |who|
        set_code_hook(who, :post, *args) { |*largs| yield(*largs) }
      end
    end

    def set_code_hook who, where, *args
      @@hooks[who][where] = Task.new(*([who,where] + (args||[]))) { |*largs| yield(*largs) } 
    end
    
    def worker_pre_fork
      @@hooks[:worker][:pre]
    end
    
    def worker_post_fork
      @@hooks[:worker][:post]
    end
    
    def manager_pre_fork
      @@hooks[:manager][:pre]
    end
    
    def manager_post_fork
      @@hooks[:manager][:post]
    end
    
  end
  
end

if $0 == __FILE__
  require 'pp'
  
  DetachedWorkers.pre_fork { |who,*xtra| puts "Running Pre-Fork in #{who.inspect}"}
  DetachedWorkers.post_fork { |who,*xtra| puts "Running Post-Fork in #{who.inspect}"}

  for i in (1..5).to_a do
    manager = DetachedWorkers::Manager.instance
    manager.add_task(i) do |spot|
      seconds = rand(5) + 2
      puts "  -- Sleeping for '#{seconds}' seconds"
      sleep seconds
    end
  end
    
  puts "Workers Total: #{manager.workers.size}"
  
  manager.complete_tasks
  
  pp manager
  
  puts "Adding more tasks"
  for i in (1..7).to_a do
    puts "Adding task #{i}"
    manager.add_task(i) do |spot|
      seconds = rand(5) + 2
      puts "--> Second Run: Sleeping '#{seconds}' seconds"
      sleep seconds 
    end
  end

  manager.complete_tasks
end
