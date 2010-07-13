class CloudAddressesController < ApplicationController
    parent_resources :user
    before_filter :login_required
    require_role  :admin, :except => [ :index, :list ],
        :unless => "current_user.has_cloud_resource_access?(CloudResource.find(params[:id]))"

    def index
        options = {
            :search => params[:search],
            :page => params[:page],
            :order => params[:sort],
            :filter => params[:filter],
            :include => [ :clusters, :instance ],
        }
        @addresses = CloudAddress.search_by_user(current_user, options)

        @parent_type = 'user'
        @parent = current_user
        @user = current_user
        respond_to do |format|
            format.html
            format.xml  { render :xml => @addresses }
            format.js
        end
    end
    def list
        index
    end

	def update
		@cloud_resource = CloudResource.find(params[:id], :include => :provider_account)

		respond_to do |format|
			if @cloud_resource.update_attributes(params[:cloud_address])
				flash[:notice] = 'Resource was successfully updated.'
	            p = @cloud_resource.provider_account
				o = @cloud_resource
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
				format.html { render :action => 'show', :anchor => params[:anchor] }
				format.xml  { head :ok }
				format.json { render :json => @cloud_resource }
			else
                @cloud_resource.status_message = @cloud_resource.errors.collect{|attr,msg| "#{attr.humanize} - #{msg}"}.join('\n')
				flash[:error] = 'There was a problem updating this resource.'
				format.html { render :action => 'show', :anchor => params[:anchor] }
				format.xml  { render :xml => @cloud_resource.errors, :status => :unprocessable_entity }
				format.json { render :json => @cloud_resource, :status => :unprocessable_entity }
			end
		end
	end

end
