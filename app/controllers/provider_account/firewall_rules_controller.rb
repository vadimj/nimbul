class ProviderAccount::FirewallRulesController < ApplicationController
    before_filter :login_required
    require_role  :admin,
        :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"
        
	def index
		@provider_account = ProviderAccount.find(params[:provider_account_id])

		joins = nil
		conditions = nil
		@firewall_rules = FirewallRule.find_all_by_provider_account(@provider_account, params[:search], params[:page], joins, conditions, params[:sort], nil, [ :security_groups, :provider_account ] )

		@partial ||= 'firewall_rules/index'
        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @firewall_rules }
            format.js   { render :partial => @partial, :layout => false }
        end
	end
	def list
		@partial = 'firewall_rules/list'
		index
	end

    def new
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @firewall_rule = FirewallRule.new

        respond_to do |format|
            format.html
            format.xml  { render :xml => @firewall_rule }
            format.js
        end
    end

    def create
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        fr_params = params[:firewall_rule]
        @firewall_rule = @provider_account.firewall_rules.build(fr_params)

        respond_to do |format|
            if @firewall_rule.save
                @firewall_rule.reload
                flash[:notice] = 'Firewall Rule was successfully created.'
                format.html { redirect_to(@firewall_rule) }
                format.xml  { render :xml => @firewall_rule, :status => :created, :location => @firewall_rule }
                format.js
            else
                @error_message = @firewall_rule.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @firewall_rule.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

    def control
        @provider_account = ProviderAccount.find(params[:provider_account_id])

        redirect_url = {
            :controller => '/provider_accounts',
            :action => 'show',
            :provider_account_id =>  @provider_account.id,
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :firewall_rules,
        }

	    @removed_firewall_rules = []
        @firewall_rules = []

        if params[:firewall_rule_ids]
            @provider_account.firewall_rules.each do |a|
                if params[:firewall_rule_ids].include?(a.id.to_s)
		            if params[:command] == 'destroy'
				        begin
			                # remove the rule from all security groups for the account
			                @provider_account.security_groups.each do |group|
			                    if group.firewall_rules.include?(a)
                		            Ec2Adapter.remove_security_group_firewall_rule(group, a)
            	                end
			                end
                            a.destroy
				            @removed_firewall_rules << a
				        rescue
                            a.status_message = "Failed to remove : #{$!}"
                            @firewall_rules << a
			            end
		            else
                        a.enable! if params[:command] == 'enable'
                        a.disable! if params[:command] == 'disable'
                        @firewall_rules << a
		            end
                end
                @message = 'Firewall Rules were successfully updated'
            end
        else
            @error_message = "No Firewall Rules to update"
        end

        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

end
