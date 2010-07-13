class Parent::AddressesController < ApplicationController
    parent_resources :provider_account, :cluster
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @addresses  = CloudAddress.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [ :clusters, :instance ])

	    @parent_type = parent_type
	    @parent = parent
	    @controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @addresses }
	        format.js
	    end
    end
    def list
        index
    end
    
    def new
        @address = CloudAddress.new

        @controls_enabled = true
        respond_to do |format|
            format.html
            format.xml  { render :xml => @address }
            format.js
        end
    end

    def create
        @address = parent.addresses.build(params[:address])

		@controls_enabled = true
        respond_to do |format|
            if @address.save and @address.allocate!
                flash[:notice] = 'Address was successfully allocated.'
	            p = parent
				o = @address
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "allocated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
                format.html { redirect_to parent, :anchor => 'addresses' }
                format.xml  { render :xml => @address, :status => :created, :location => @address }
                format.js
            else
                @error_message ||= @address.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @address.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

    def control
        joins = nil
	    conditions = nil
	    @addresses  = CloudAddress.find_all_by_parent(parent, params[:address_ids], params[:page], joins, conditions, params[:sort], nil, :provider_account)

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :addresses,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)
        
        @error_message = ''
        if @addresses.size == 0
		    @error_message = "No addresses are specified."
        else
		    @addresses.each do |a|
				begin
					a.release! if params[:command] == 'release'
				rescue
					a.errors.add(:state, "Failed to #{params[:command]} address '#{a.name}': #{$!}")
				end
                if a.errors.empty?
		            p = parent
					o = a
					AuditLog.create_for_parent(
						:parent => p,
						:auditable_id => nil,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "de-allocated '#{o.name}'",
						:changes => o.tracked_changes,
						:force => true
					)
				else
					@error_message += a.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
		    end
		    @message = "Addresses #{params[:command]}ed." if @error_message.blank?
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
