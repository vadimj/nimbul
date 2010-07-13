class ProviderAccount::ServerImagesController < ApplicationController
    parent_resources :provider_account
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
		# commented out refresh from ui for performance reasons
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')
	    
        joins = nil
	    conditions = nil
	    @server_images  = ServerImage.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [:provider_account])

        @parent_type = parent_type
        @parent = parent
		@controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @server_images }
	        format.js
	    end
	end
	def list
		index
	end

    def new
        @server_image = ServerImage.new

        @parent_type = parent_type
        @parent = parent
		@controls_enabled = true
        respond_to do |format|
            format.html
            format.xml  { render :xml => @server_image }
            format.js
        end
    end

    def create
        @server_image = parent.server_images.build(params[:server_image])

        @parent_type = parent_type
        @parent = parent
		@controls_enabled = true
        respond_to do |format|
            if @server_image.save and @server_image.allocate!
                flash[:notice] = 'Server image was successfully added.'
                format.html { redirect_to @provider_account, :anchor => 'server_images' }
                format.xml  { render :xml => @server_image, :status => :created, :location => @server_image }
                format.js
            else
                @error_message ||= @server_image.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @server_image.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

    def control
        @provider_account = ProviderAccount.find(params[:provider_account_id], :include => [ :server_images ])
        @server_images = (@provider_account.server_images.find(params[:server_image_ids]))

        redirect_url = {
            :controller => '/provider_accounts',
            :action => 'show',
            :provider_account_id =>  @provider_account.id,
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :server_images,
        }
        
        @error_message = ''
        if @server_images.size == 0
		    @error_message = "No server images to update."
        else
		    @server_images.each do |a|
				if params[:command] == 'release'
					if !a.server_profile_revisions.empty?
						@error_message += "Couldn't release #{a.name} - it's being used by some server profiles."
					else
						a.release!
					end
                end
                a.enable! if params[:command] == 'enable'
                a.disable! if params[:command] == 'disable'
                if a.errors
					@error_message += a.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
		    end
		    @message = "Server images updated."
        end

        @controls_enabled = true
        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @error_message, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end

#class ProviderAccount::ServerImagesController < ApplicationController
#    before_filter :login_required
#    require_role  :admin,
#        :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id])) "
#  
#    def update
#        @provider_account = ProviderAccount.find(params[:provider_account_id])
#
#        redirect_url = {
#            :controller => '/provider_accounts',
#            :action => 'show',
#            :provider_account_id =>  @provider_account.id,
#            :search => params[:search],
#            :sort => params[:sort],
#            :page => params[:page],
#            :anchor => :server_images,
#        }
#
#        @new_server_images = []
#        @server_images = []
#        @removed_server_images = []
#
#        if params[:add]
#            server_image_attributes = params[:provider_account][:server_image_attributes]
#            server_image_attributes.each do |attributes|
#                if attributes[:id].blank?
#                    server_image = @provider_account.server_images.build(attributes)
#                end
#                if server_image.save
#                    @new_server_images << server_image
#                else
#                    @error_message = server_image.errors.collect{ |e| "Server Image: #{e[0]} - #{e[1]}" }.join('<br />')
#                end
#            end
#            @message = 'Server Images were successfully added' if @error_message.blank?
#        elsif params[:server_image_ids]
#            @provider_account.server_images.each do |a|
#                if params[:server_image_ids].include?(a.id.to_s)
#                    if params[:command] == 'destroy'
#                        if a.destroy
#                            @removed_server_images << a
#                        else
#                            @server_images << a
#                        end
#                    else
#                        a.enable! if params[:command] == 'enable'
#                        a.disable! if params[:command] == 'disable'
#                        @server_images << a
#                    end
#                end
#                @message = 'Server Images were successfully updated'
#            end
#        else
#            @error_message = "No Server Image to update"
#        end
#
#        respond_to do |format|
#            if @error_message.blank?
#                flash[:notice] = @message
#                format.html { redirect_to redirect_url }
#                format.xml  { head :ok }
#                format.js
#            else
#                flash[:error] = @error_message
#                format.html { redirect_to redirect_url }
#                format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
#                format.js
#            end
#        end
#    end
#
#end
