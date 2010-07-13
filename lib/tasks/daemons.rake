namespace :daemons do
    desc "Start daemons"
    task :start => :environment do
        `#{daemons_script} start`
    end

    desc "Stop daemons"
    task :stop => :environment do
        `#{daemons_script} stop`
    end

    desc "Restart daemons"
    task :restart => :environment do
        `#{daemons_script} restart`
    end

    def daemons_script
        Dir[File.dirname(__FILE__) + "/../../script/daemons"]
    end
end
