module PublishersHelper
    def delete_publisher_link(text, publisher, options={})
        provider_account = publisher.provider_account
        url = provider_account_publisher_url(provider_account, publisher)
        options = {
            :url => url,
            :method => :delete,
            :confirm => "Are you sure you want to delete '#{publisher.class_type}' [#{publisher.id}]?",
        }
        html_options = {
            :title => "Delete '#{publisher.class_type}' [#{publisher.id}]",
            :href => url,
            :method => :delete,
        }.merge!(options)
        link_to_remote text, options, html_options
    end

    def delete_publisher_image_link(text, publisher)
    	delete_publisher_link(
            image_tag(
                'trash.png', :class => 'control-icon', :alt => text
            ), publisher 
        )
    end
    
    def run_publisher_link(text, publisher)
	url = run_publisher_url(publisher)
        options = {
            :complete => visual_effect(:highlight, :last_published),
            :url => url,
        }
        html_options = {
            :title => "Run '#{publisher.class_type}' [#{publisher.id}] Now",
            :href => url,
        }
        link_to_remote text, options, html_options
    end

    def run_publisher_image_link(text, publisher)
    	run_publisher_link(
            image_tag(
                'publish.png', :class => 'control-icon', :alt => text
            ), publisher 
        )
    end
    
    def verify_publisher_link(text, publisher)
	url = verify_publisher_url(publisher)
        options = {
            :url => url,
        }
        html_options = {
            :href => url,
            :title => "Verify '#{publisher.class_type}' [#{publisher.id}]",
        }
        link_to_remote text, options, html_options
    end

    def verify_publisher_image_link(text, publisher)
    	verify_publisher_link(
            image_tag(
                'verify.png', :class => 'control-icon', :alt => text
            ), publisher 
        )
    end
    
end
