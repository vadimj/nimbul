# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

begin
  DEFAULT_METRICS = [:stats, :churn, :saikuro, :flay, :flog, :reek, :roodi, :rcov]
  DEFAULT_GRAPHS  = [:flog, :flay, :reek, :roodi, :rcov]

  require 'metric_fu'
  MetricFu::Configuration.run do |config|

    config.metrics  = ((ENV['METRICS'].split(' ') rescue nil) || DEFAULT_METRICS).collect { |m| m.to_sym }

    # uncomment if you want google charts instead. you'll need 
    # to install the gem as well: sudo gem install googlecharts
    config.graph_engine = :gchart

    config.graphs   = ((ENV['GRAPHS'].split(' ') rescue nil) || DEFAULT_GRAPHS).collect { |m| m.to_sym }

    config.flay     = { :dirs_to_flay => ['app', 'lib']  }
    config.flog     = { :dirs_to_flog => ['app', 'lib']  }
    config.reek     = { :dirs_to_reek => ['app', 'lib']  }
    config.roodi    = { :dirs_to_roodi => ['app', 'lib'] }

    config.saikuro  = { 
      :input_directory  => ['app', 'lib'],
      :output_directory => 'tmp/metrics/saikuro', 
      :cyclo            => '', 
      :filter_cyclo     => '0', 
      :warn_cyclo       => '5', 
      :error_cyclo      => '7',
      :formater         => 'text'
    } 

    config.churn    = { 
      :start_date => '1 year ago', 
      :minimum_churn_count => 10
    }

    config.rcov     = {
      :environment => 'test',
      :test_files => [
        'spec/**/*_spec.rb', 
        'test/**/*_test.rb',
      ],
      :rcov_opts => [
        '--sort name', 
        '--text-coverage',
        '--no-color', 
        '--profile',
        '--xrefs',
        '--rails', 
        '--exclude /gems/,/Library/,spec,/usr/,/opt/'
      ],
      :external => nil
    }
  end
rescue LoadError
  # if we can't load metric stuff, skip it
  warn "metrics not available - install metric_fu for metrics"
end


