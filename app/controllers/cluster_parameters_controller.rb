class ClusterParametersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "params[:cluster_id].nil? or current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

    # POST /cluster_parameters
    # POST /cluster_parameters.xml
    def create
        @cluster = Cluster.find(params[:cluster_id], :include => :provider_account)
        redirect_url = url_for(
                    :id => @cluster.id,
                    :controller => 'clusters',
                    :action => 'show',
                    :anchor => 'variables')
        respond_to do |format|
            if @cluster.update_attributes(params[:cluster])
				p = @cluster.provider_account
				o = @cluster
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "updated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => false
				)
                flash[:notice] = 'Cluster Variables were successfully updated.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @cluster, :status => :updated, :location => @cluster }
            else
                flash[:error] = "Failed to update Cluster Variables"
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
            end
        end
    end

    def sort
        params[:cluster_parameters].each_with_index do |id, index|
            ClusterParameter.update_all(['position=?', index+1], ['id=?', id])
        end
        render :nothing => true
    end
end
