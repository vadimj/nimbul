namespace :rails do
    desc "Give path to current rails root"
    task :root => :environment do
        puts RAILS_ROOT
    end
end

