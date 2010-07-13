module AutoScalingHelper
	def as_sort_link(text, param, update, refresh = nil)
        key = param
        key += "_reverse" if params[:sort] == param
		
		url = list_provider_account_auto_scaling_path(
			@provider_account,
			params.merge({:sort => key, :page => nil, :refresh => refresh})
		)

        options = {
			:url => url,
			:update => update,
		}
        
        html_options = {
			:title => "Sort by this field", :href => url,
		}
        
        link_to_remote(text, options, html_options)
    end
end