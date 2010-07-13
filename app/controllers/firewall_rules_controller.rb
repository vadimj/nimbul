class FirewallRulesController < ApplicationController
	before_filter :login_required
	require_role  :admin,
	    :unless => "(!params[:id].nil? and current_user.has_firewall_rule_access?(FirewallRule.find(params[:id]))) or "+
		       "(!params[:provider_account_id].nil? and current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))) "

	# GET /firewall_rules/1
	# GET /firewall_rules/1.xml
	def show
		@firewall_rule = FirewallRule.find(params[:id], :include => [ :firewall_rule_params, :security_groups ])
    	@firewall_rule_params = @firewall_rule.firewall_rule_params
		@security_groups = @firewall_rule.security_groups

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @firewall_rule }
		end
	end

	def edit
		@firewall_rule = FirewallRule.find(params[:id])
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @firewall_rule }
		end
	end

    def update
        @firewall_rule = FirewallRule.find(params[:id])
        
        respond_to do |format|
            if @firewall_rule.update_attributes(params[:firewall_rule])
                flash[:notice] = 'Firewall Rule was successfully updated.'
                format.html { redirect_to(@firewall_rule) }
                format.xml  { head :ok }
                format.js   { render :partial => 'firewall_rules/firewall_rule', :layout => false }
				format.json { render :json => @firewall_rule }
            else
                flash[:error] = 'There was a problem updating this Firewall Rule.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @firewall_rule.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'firewall_rules/firewall_rule', :layout => false }
				format.json { render :json => @firewall_rule }
            end
        end
    end

  # DELETE /firewall_rules/1
  # DELETE /firewall_rules/1.xml
  def destroy
    @cluster = Cluster.find(params[:cluster_id])
    @firewall_rule = FirewallRule.find(params[:id])
    @firewall_rule.destroy

    respond_to do |format|
      format.html { redirect_to @cluster }
      format.xml  { head :ok }
      format.js
    end
  end

end
