class SecurityGroupsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
	    :unless => "current_user.has_security_group_access?(SecurityGroup.find(params[:id]))"

	def show
		@security_group = SecurityGroup.find(params[:id], :include => [ :firewall_rules ])
		@editable = false
	end

	def edit
		@security_group = SecurityGroup.find(params[:id], :include => [ :firewall_rules ])
		@editable = true
	end

    def update
		@security_group = SecurityGroup.find(params[:id])
        redirect_url = provider_account_path(@security_group.provider_account, :anchor => :security_groups)

	    if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
		    respond_to do |format|
		        if @security_group.update_attributes(params[:security_group])
		            flash[:notice] = 'Security group was successfully updated.'
		            format.html { render :action => "edit" }
		            format.xml  { head :ok }
		            format.js   { render :partial => 'security_groups/security_group', :layout => false }
					format.json { render :json => @security_group }
		        else
		            flash[:error] = 'There was a problem updating this Security Group.'
		            format.html { render :action => "edit" }
		            format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
		            format.js   { render :partial => 'security_groups/security_group', :layout => false }
					format.json { render :json => @security_group }
		        end
		    end
		end
    end
    
    # auto_complete_for :firewall_rule, :id
    def auto_complete_for_firewall_rule_id(options = {})
		@security_group = SecurityGroup.find(params[:id])
        @search = params[:firewall_rule_search]
        
        conditions = [ "provider_account_id=? and (LOWER(name) LIKE ? OR LOWER(ip_range) LIKE ? OR LOWER(group_name) LIKE ?)" ]
        conditions << @security_group.provider_account_id
        conditions << ('%' + @search + '%')
        conditions << ('%' + @search + '%')
        conditions << ('%' + @search + '%')
        order = 'name ASC'
        find_options = {
            :conditions => conditions,
            :order => order,
            :limit => 10 }.merge!(options)

        @firewall_rules = FirewallRule.find(:all, find_options)

        tags = "<%= content_tag(:ul, @firewall_rules.map{ |firewall_rule| content_tag(:li, firewall_rule_description(firewall_rule, @search)) }) %>"
        render :inline => tags
    end
end
