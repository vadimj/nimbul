class SecurityGroup::FirewallRulesController < ApplicationController
    before_filter :login_required
    require_role  :admin,
        :unless => "current_user.has_security_group_access?(SecurityGroup.find(params[:security_group_id])) "

    def create
        @security_group = SecurityGroup.find(params[:security_group_id])
        @firewall_rule = FirewallRule.find(params[:firewall_rule][:id])

        if @firewall_rule.nil?
            @error_message = "Couldn't locate Firewall Rule [#{params[:firewall_rule][:id]}]"
        elsif @security_group.firewall_rules.include?(@firewall_rule)
            @error_message = "Firewall Rule '#{@firewall_rule.name}' is already included in #{@security_group.name}"
        else
            begin
                Ec2Adapter.add_security_group_firewall_rule(@security_group, @firewall_rule)
                @message = "Added '#{@firewall_rule.name}' to #{@security_group.name}"
            rescue
                @error_message = "Failed to add '#{@firewall_rule.name}': #{$!}"
            end
        end

        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @security_group }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @security_group }
				format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
				format.js
			end
	    end
    end

    def destroy
        @security_group = SecurityGroup.find(params[:security_group_id])
        @firewall_rule = FirewallRule.find(params[:id])        

        if @firewall_rule.nil?
            @error_message = "Couldn't locate Firewall Rule [#{params[:firewall_rule][:id]}]"
        elsif !@security_group.firewall_rules.include?(@firewall_rule)
            @error_message = "Firewall Rule '#{@firewall_rule.name}' is not in #{@security_group.name}"
        else
            begin
                Ec2Adapter.remove_security_group_firewall_rule(@security_group, @firewall_rule)
                @message = "Remove '#{@firewall_rule.name}' from #{@security_group.name}"
            rescue
                @error_message = "Failed to remove '#{@firewall_rule.name}': #{$!}"
                @firewall_rule.status_message = "Failed to remove: #{$!}"
            end
        end

        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @security_group }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @security_group }
				format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end

