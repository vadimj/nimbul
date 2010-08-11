class ProviderAccount::SecurityGroupsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
	    :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"

	def index
		@provider_account = ProviderAccount.find(params[:provider_account_id])
	    @provider_account.refresh(params[:refresh]) if params[:refresh] and @provider_account.respond_to?('refresh')
		
		joins = nil
		conditions = nil
	    @security_groups = SecurityGroup.search_by_provider_account(@provider_account, params[:search], params[:page], joins, conditions, params[:sort], nil, [:servers, :instances, :provider_account])

		@partial ||= 'security_groups/index'
		@controls_enabled = true
        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @security_groups }
            format.js   { render :partial => @partial, :layout => false }
        end
	end
	def list
		@partial = 'security_groups/list'
		index
	end
	
    def new
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @security_group = SecurityGroup.new

        respond_to do |format|
            format.html
            format.xml  { render :xml => @security_group }
            format.js
        end
    end

    def create
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        fr_params = params[:security_group]
	    if fr_params[:name].blank? or fr_params[:description].blank?
	        @error_message = "Both Name and Description are required"
	    else
	        @security_group = @provider_account.security_groups.build(fr_params)
	        begin
		        Ec2Adapter.create_security_group(@security_group)
	        rescue
		        @security_group = nil
		        @error_message = "Failed to register Security Group with Amazon: #{$!}"
	        end
	    end

        respond_to do |format|
            if !@security_group.nil? and @security_group.save
                @security_group.reload
		        @message = 'Security Group was successfully created.'
                flash[:notice] = @message
                format.html { redirect_to(@security_group) }
                format.xml  { render :xml => @security_group, :status => :created, :location => @security_group }
                format.js
            else
		        @error_message ||= ''
                @error_message += @security_group.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />') if !@security_group.nil? and  !@security_group.errors.nil?
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end	

    def destroy
        @provider_account = ProviderAccount.find(params[:provider_account_id], :include => [ :security_groups ])
        @security_group = @provider_account.security_groups.detect{ |g| g.id == params[:id].to_i }

        @removed_security_groups = []
        @security_groups = []

        if @security_group.nil?
            @error_message = "Couldn't find a Security Group"
        else
            begin
                Ec2Adapter.delete_security_group(@security_group)
                @security_group.destroy
                @removed_security_groups << @security_group
                @message = "Successfully deleted #{@security_group.name}"
            rescue
                @security_group.status_message = "Failed to delete: #{$!}"
                @security_groups << @security_group
            end
        end

        respond_to do |format|
            format.html
            format.xml  { render :xml => @security_group }
            format.js
        end
    end
end
