class ServerImagesController < ApplicationController
    parent_resources :user
	before_filter :login_required
	require_role  :admin, :except => [ :index, :list ],
		:unless => "params[:id].nil? or current_user.has_server_image_access?(ServerImage.find(params[:id])) "

	def index
		options = {
			:search => params[:search],
			:page => params[:page],
			:order => params[:sort],
            :filter => params[:filter],
	        :include => [ :provider_account ],
		}
		@server_images = ServerImage.search_by_user(current_user, options)

        @parent_type = 'user'
        @parent = current_user
	    @user = current_user
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @servers }
	        format.js
	    end
	end
	def list
		index
	end

    def update
        @server_image = ServerImage.find(params[:id])
        
        respond_to do |format|
            if @server_image.update_attributes(params[:server_image])
                flash[:notice] = 'Server image was successfully updated.'
                format.html { redirect_to(@server_image) }
                format.xml  { head :ok }
                format.js   { render :partial => 'server_images/server_image', :layout => false }
				format.json { render :json => @server_image }
            else
                flash[:error] = 'There was a problem updating this Server Image.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @server_image.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'server_images/server_image', :layout => false }
				format.json { render :json => @server_image }
            end
        end
    end
end
