class StatsAdapter
    def self.refresh_account(provider_account, period=5.minutes)
        # collect this 5 minutes stats (if they haven't been collected already)
    		now = Time.now
        this_period = Time.at((now.to_f / period).floor * period)
        stat_record = StatRecord.find(:first, :conditions => [
                'provider_account_id=:provider_account_id AND taken_at=:taken_at',
                { :provider_account_id => 1, :taken_at => this_period.utc }
        ] )
        unless stat_record
            stat_record = StatRecord.new({
                :provider_account_id => provider_account.id,
                :taken_at => this_period,
            })
            stat_record.save
            iaRecords = InstanceAllocationRecord.find_by_sql([
                "select server_id, zone_id, instance_type, count(id) as running from instances where provider_account_id=? and state='running' group by server_id, zone_id, instance_type order by zone_id, instance_type",
                provider_account.id
            ])
            iaRecords.each do |iaRecord|
                server_id = nil
                server_name = ''
                cluster_id = nil
                cluster_name = ''
                unless iaRecord.server_id.blank?
                    server = Server.find(iaRecord.server_id)
                    cluster = Cluster.find(server.cluster_id) if server
                    server_id = server.id if server
                    server_name = server.name if server
                    cluster_id = cluster.id if cluster
                    cluster_name = cluster.name if cluster
                end
                instance_allocation_record = stat_record.instance_allocation_records.build({
                    :server_id => server_id,
                    :server_name => server_name,
                    :cluster_id => cluster_id,
                    :cluster_name => cluster_name,
                    :zone_id => iaRecord.zone_id,
                    :instance_type => iaRecord.instance_type,
                    :running => iaRecord.running,
                })
                instance_allocation_record.save 
            end
        end
    rescue Exception => e
      Rails.logger.error "#{e.class.name}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end
end
