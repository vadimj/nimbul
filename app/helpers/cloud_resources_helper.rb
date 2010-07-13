module CloudResourcesHelper
    def add_cloud_resource_cluster_link(text, cloud_resource)
        url = new_cloud_resource_cluster_url(cloud_resource)
        options = {
            :url => url,
            :method => :get,
        }
        html_options = {
            :title => "Enable this #{cloud_resource.short_type} for a Cluster",
            :href => url,
            :method => :get,
        }
        link_to_remote text, options, html_options
    end
    
   	def remove_cloud_resource_cluster_link(link_text, cloud_resource, cluster)
		url = cloud_resource_cluster_url(cloud_resource, cluster)
    	options = {
            :url => url,
            :method => :delete,
            :confirm => "Are you sure you want to disable #{cloud_resource.short_type} '#{cloud_resource.name}' for cluster '#{cluster.name}'?",
		}
		html_options = {
			:title => "Disable #{cloud_resource.short_type} '#{cloud_resource.name}' for cluster '#{cluster.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
   	end
   	
    def polymorphic_cloud_resource_select(form, class_field, class_value, id_field, id_value, cloud_resources, options={}, filter_field=nil, mount_types=[] )
		cloud_resources =  cloud_resources.is_a?(Array) ? cloud_resources : [ cloud_resources ]
		
		resource_classes = []
		resources = []
		CloudResource.classes_and_resources(cloud_resources, mount_types) do |c, r|
			resource_classes = c
			resources = r
		end

		locals = {
			:form => form,
			:class_field => class_field,
			:class_value => class_value,
			:id_field => id_field,
			:id_value => id_value,
			:resource_classes => resource_classes,
			:resources => resources,
			:options => options,
			:filter_field => filter_field,
		}
		render :partial => 'cloud_resources/polymorphic_select', :locals => locals
    end
    
end
