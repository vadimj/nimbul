class CloudResource::ClustersController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_provider_account_access?(CloudResource.find(params[:cloud_resource_id]).provider_account) "

	def new
        @cloud_resource = CloudResource.find(params[:cloud_resource_id])
        @provider_account = @cloud_resource.provider_account
        @cluster = Cluster.new
        
		respond_to do |format|
			format.html
			format.xml  { render :xml => @cluster }
			format.js
		end
    end		

    def create
        @cloud_resource = CloudResource.find(params[:cloud_resource_id])
        @provider_account = @cloud_resource.provider_account
        @cluster = @provider_account.clusters.find(params[:cluster][:id])

        if @cluster.nil?
            @error_message = "Couldn't locate Cluster [#{params[:cluster][:id]}] under Provider Account '#{@provider_account.name}'."
        elsif @cloud_resource.clusters.include?(@cluster)
            @error_message = "Cluster '#{@cluster.name}' is already allowed to use #{@cloud_resource.name}."
        elsif @cloud_resource.clusters << @cluster
			@message = "Cluster '#{@cluster.name}' can now use #{@cloud_resource.name}."
        else
			@error_message ||= @cloud_resource.errors.collect{ |attr, msg| attr.humanize+' - '+msg }.join('<br />')
        end

        @controls_enabled = true
        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @cloud_resource }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @cloud_resource }
				format.xml  { render :xml => @cloud_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def destroy
        @cloud_resource = CloudResource.find(params[:cloud_resource_id])
        @provider_account = @cloud_resource.provider_account
        @cluster = @provider_account.clusters.find(params[:id])
        @servers = ( @cloud_resource.server_resources.collect{ |sr| sr.resource_bundle.server } )
        
        unless ( @cluster.servers & @servers ).empty?
			@error_message = "Can't revoke access to #{@cloud_resource.name} from #{@cluster.name}, some servers in #{@cluster.name} use the resource."
		end
        
        @controls_enabled = true
        respond_to do |format|
			if @error_message.blank? and @cloud_resource.clusters.delete(@cluster)
				flash[:notice] = "Revoked access to #{@cloud_resource.name} from #{@cluster.name}."
                format.html { redirect_to @provider_account }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= "Failed to revoke access to #{@cloud_resource.name} from #{@cluster.name}."
				flash[:error] = @error_message
                format.html { redirect_to @provider_account }
				format.xml  { render :xml => @cloud_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def auto_complete_for_cluster_id(options = {})
		@cloud_resource = CloudResource.find(params[:cloud_resource_id])
        @provider_account = @cloud_resource.provider_account
        @search = params[:cluster_search]
        @clusters = Cluster.find_all_by_provider_account(@provider_account, params[:cluster_search], nil, nil, nil, 'name')

        tags = "<%= content_tag(:ul, @clusters.map{ |cluster| content_tag(:li, cluster_description(cluster, @search)) }) %>"
        render :inline => tags
    end
end

