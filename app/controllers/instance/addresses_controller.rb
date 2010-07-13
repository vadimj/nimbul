class Instance::AddressesController < Instance::InstanceResourcesController
    def index
        @instance_addresses = InstanceAddress.find_all_by_instance_id(params[:instance_id], :include => :cloud_resource )
        self.prepare_resources

	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @instance_addresses }
	        format.js
	    end
    end
    def list
        index
    end
end

