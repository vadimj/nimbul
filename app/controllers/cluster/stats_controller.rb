class Cluster::StatsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

	def index
        @cluster = Cluster.find(params[:cluster_id])
        @cluster_names = ( @cluster.name )
        @latest_stat_record = StatRecord.find_by_provider_account_id(@cluster.provider_account_id, :order => 'taken_at DESC', :include => :instance_allocation_records)
        @zone_type_stats = Hash.new()
        @latest_stat_record.instance_allocation_records.each do |iar|
            next unless iar.cluster_id == @cluster.id
            @zone_type_stats[iar.zone] = Hash.new unless @zone_type_stats[iar.zone]
            @zone_type_stats[iar.zone].store(iar.instance_type, Hash.new) unless @zone_type_stats[iar.zone][iar.instance_type]
            current_value = @zone_type_stats[iar.zone][iar.instance_type]['Total'] || 0
            @zone_type_stats[iar.zone].fetch(iar.instance_type).store('Total', current_value + iar.running.to_i)
            current_cluster_value =  @zone_type_stats[iar.zone][iar.instance_type][iar.cluster_name] || 0
            @zone_type_stats[iar.zone].fetch(iar.instance_type).store(iar.cluster_name, current_cluster_value + iar.running.to_i)
        end

        respond_to do |format|
            format.html
            format.xml  { render :xml => @latest_stat_record }
            format.js   { render :partial => 'stats/list', :layout => false }
        end
	end

end
