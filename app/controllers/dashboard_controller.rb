class DashboardController < ApplicationController
    before_filter :login_required
    
    def index
        @overview = {}
        
        count_objects = []
        objects_to_count = [
			:provider_accounts, :server_images,
			:clusters, :cloud_addresses,
			:servers, :cloud_volumes,
			:instances, :cloud_snapshots
		]
        objects_to_count.each do |c|
            count_objects << LabelValue.new(c, c.to_s.classify.constantize.count_all_by_user(current_user))
        end
        @overview[:objects] = count_objects
        
		options = {
			:search => params[:search],
			:page => params[:page],
			:joins => nil,
			:conditions => nil,
			:order => params[:sort],
			:filter => nil,
			:include => nil,
		}

        respond_to do |format|
            format.html
        	format.xml  { render :xml => @overview }
        	format.js
        end
    end
end