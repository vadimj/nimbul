# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	include SortableTable::App::Helpers::ApplicationHelper

	FLASH_NOTICE_KEYS = [:error, :notice, :warning]

    def title(title)
        content_for(:title) { title }
    end

    def subtitle(object)
        result = pagetitle(object)
        result = ': ' + result unless result.empty?
        content_for(:subtitle) { result }
    end

    def capitalize(str)
        str if str.nil?
        str.split(' ').map {|w| w.capitalize }.join(' ')
    end

    def pagetitle(object, parameters={})
        return '' if object.nil?
        path = []
        separator = ': '
        if object.is_a? String
			return object.to_s
        elsif object.respond_to? :name
            name = h(object.name)
            name = capitalize(name) unless object.is_a?(Instance)
			if parameters[:edit_in_place]
				begin
					path << edit_in_place(object, :name)
				rescue
					path << name
				end
			else
				path << name
			end
			parent_array(object).each do |p|
	            if parameters[:create_links]
	     			path << link_to(h(p.name), p)
	            else
	                path << capitalize(h(p.name))
	            end
			end
        else
			path << capitalize(h(object.to_s))
        end

        result = path.length > 0 ? path.reverse.join(separator) : '' 
        return result
    end
    
    def parent_links(object, separator=': ')
		path = []
		parent_array(object).each do |p|
			path << link_to(h(p.name), p)
		end
		result = path.length > 0 ? path.reverse.join(separator) : ''
		return result
    end
    
    def parent_array(object)
		parents = []
		if object.respond_to? :server and !object.server.nil?
			object = object.server
			parents << object
		end
		if object.respond_to? :cluster and !object.cluster.nil?
			object = object.cluster
			parents << object
		end
		if object.respond_to? :provider_account and !object.provider_account.nil?
			object = object.provider_account
			parents << object
		end
		return parents
    end

    def javascript(*files)
        content_for(:head) { javascript_include_tag(*files) }
    end

    def stylesheet(*files)
        content_for(:head) { stylesheet_link_tag(*files) }
    end

	def flash_messages
		return unless messages = flash.keys.select{|k| FLASH_NOTICE_KEYS.include?(k)}
		formatted_messages = messages.map do |type|
			content_tag :div, :id => 'flash', :class => type.to_s do
				message_for_item(flash[type], flash["#{type}_item".to_sym])
			end
		end
		formatted_messages.join
	end

    def message_for_item(message, item = nil)
        if item.is_a?(Array)
            message % link_to(*item)
        else
            message % item
        end
    end

	def editable(object, attribute)
		object_name = ActionController::RecordIdentifier.singular_class_name(object)
		column = object.try(:column_for_attribute, attribute)

		editfield = case column.try :type
			when :enum:
				{ :editField => { :type => :select, :options => column.limit.map{|c| [c,c]} } }
			else
				{}
		end

		edit_in_place(object, attribute, :tag => :div) +
		javascript_tag("
			var element_id = '#{object_name}_#{object.id}_#{attribute.to_s}';
			if ($(element_id)) { new Editable(element_id, #{editfield.to_json}); }
		")
	end

	def editable_list(object, attribute, list = {}, options = {})
		object_name = ActionController::RecordIdentifier.singular_class_name(object)

		editfield = {
			:editField => { :type => :select, :options => list },
			:format => ( options.try(:format) || :json )
		}

		edit_in_place(object, attribute, { :tag => :div }.merge(options.dup)) +
		javascript_tag("
			var element_id = '#{object_name}_#{object.id}_#{attribute.to_s}';
			if ($(element_id)) { new Editable(element_id, #{editfield.to_json}); }
		")
	end

	def if_admin?
    	yield if logged_in? && current_user.has_role?('admin')
	end

	def if_cluster_admin?(cluster_in_question)
		yield if logged_in? && current_user.has_cluster_access?(cluster_in_question)
	end

	def if_logged_in?
		yield if logged_in?
	end

	def if_recaptcha?
		yield if @bad_visitor
	end

	def in_beta?
		APP_CONFIG['settings']['in_beta']
	end

	def if_in_beta?
		yield if in_beta?
	end

	def unless_in_beta?
		yield unless in_beta?
	end

	def if_invites_available?
		yield if in_beta? and logged_in? and (current_user.invitation_limit > 0)
	end

	def focus_on_div(div)
	  update_page do |page|
	    page[div].focus
	  end
	end

	# paginating helper
	def will_paginate_remote(collection, update)
		# add parameters
		with = nil
		ps = []
		ps << "'provider_account_id=' + encodeURIComponent('#{params[:provider_account_id]}')" unless params[:provider_account_id].blank?
		ps << "'security_group_id=' + encodeURIComponent('#{params[:security_group_id]}')" unless params[:security_group_id].blank?
		ps << "'cluster_id=' + encodeURIComponent('#{params[:cluster_id]}')" unless params[:cluster_id].blank?
		ps << "'server_id=' + encodeURIComponent('#{params[:server_id]}')" unless params[:server_id].blank?
		ps << "'search=' + encodeURIComponent('#{params[:search]}')" unless params[:search].blank?
		ps << "'sort=' + encodeURIComponent('#{params[:sort]}')" unless params[:sort].blank?
		if ps.size > 0
			with = ps.join(" + '&amp;' + ")
		end
		wp_tag = will_paginate collection,
			:renderer => 'RemoteLinkRenderer',
			:remote => {
				:update => update,
				:with => with
			}
        if wp_tag.nil?
            ''
        else
            wp_tag + '<br />'
        end
	end

	# paginate search field helper
	def will_paginate_search_field(name, update, controller, action, title = '' )
		# add parameters
		with = nil
		ps = []
		ps << "'provider_account_id=' + encodeURIComponent('#{params[:provider_account_id]}')" unless params[:provider_account_id].blank?
		ps << "'security_group_id=' + encodeURIComponent('#{params[:security_group_id]}')" unless params[:security_group_id].blank?
		ps << "'cluster_id=' + encodeURIComponent('#{params[:cluster_id]}')" unless params[:cluster_id].blank?
		ps << "'server_id=' + encodeURIComponent('#{params[:server_id]}')" unless params[:server_id].blank?
		ps << "'search=' + encodeURIComponent($('#{name}').value)"
		ps << "'#{name}=' + encodeURIComponent($('#{name}').value)"
		if ps.size > 0
			with = ps.join(" + '&' + ")
		end
		
		if !controller.nil?
			url = { :controller => controller, :action => action }
		else
			url = { :action => action }
		end
		
		html_options = {
            :size => 10,
            :title => title,
            :onkeypress => "return disableEnterKey(event)",
            :class => 'search',
        }
		
		field_tag = text_field_tag(name, params[name], html_options)
		
		observe_tag = observe_field name,
			:frequency => 2,
    		:update => update,
    		:url => url,
			:method => :get,
			:with => with
		field_tag + observe_tag
	end

	def refresh_link(text, refresh, controller, action, update = refresh)
		params[:action] = action
		with = nil
		ps = []
		ps << "'search=' + encodeURIComponent($(this).previous('.search').value)"
		if ps.size > 0
			with = ps.join(" + '&' + ")
		end

		url = {
			:controller => controller, :action => action,
			:params => params.merge({:refresh => refresh, :page => nil})
		}
		
		href = url_for(
			:controller => controller, :action => action,
			:params => params.merge({:page => nil})
		)
		
		options = {
			:url => url,
			:update => update,
		}
		options[:with] = with unless with.nil?
		
		html_options = {
			:href => href,
			:title => "Refresh",
		}
		link_to_remote(text, options, html_options)
	end
	
	def refresh_image(text, refresh, controller, action, update = refresh)
        link_text = image_tag("refresh.png", :class => "control-icon", :alt => text)
        refresh_link link_text, refresh, controller, action, update
	end

	def refresh_checkbox(text, refresh, controller, action, update = refresh, frequency = 10)
		params[:action] = action
		url = {
			:controller => controller, :action => action,
			:params => params.merge({:refresh => refresh, :page => nil})
		}
		
		href = url_for(
			:controller => controller, :action => action,
			:params => params.merge({:refresh => refresh, :page => nil})
		)
		
		options = {
			:url => url,
			:update => update,
			:condition => "autorefresh_#{refresh} == true",
			:frequency => frequency,
		}
		
		html_options = {
			:href => href,
			:title => "Refresh",
		}
		js_tag = javascript_tag "var autorefresh_#{refresh} = true;"
		control_tag = ''
		control_tag += check_box_tag "autorefresh_#{refresh}", '1', 1, :onclick => "autorefresh_#{refresh} = !autorefresh_#{refresh};"
		control_tag += '&nbsp;'
		control_tag += label_tag "autorefresh_#{refresh}", text
		rp_tag = periodically_call_remote(options)		
		return (js_tag + control_tag + rp_tag)
	end

	def refresh_periodically(name, update, controller, action, frequency = 10)
		params[:action] = action
        url = {
            :controller => controller, :action => action,
            :params => params.merge({:refresh => update, :page => nil})
        }
		options = {
            :url => url,
            :update => update,
			:condition => "autorefresh == true",
			:frequency => frequency,
        }
		js_tag = javascript_tag "var autorefresh = true;"
		control_tag = ''
		control_tag += check_box_tag 'autorefresh', '1', 1, :onclick => "autorefresh = !autorefresh;"
		control_tag += '&nbsp;'
		control_tag += label_tag 'autorefresh', name
		rp_tag = periodically_call_remote(options)
		js_tag + control_tag + rp_tag
	end

	def selectable_filter_link(text, url, update)
		href = url
		options = {
			:url => url,
			:update => update,
		}
		html_options = {
			:href => href,
			:title => "Filter by #{text}",
			:onclick => "select_parent_element($(this));",
		}
		# TODO make it link_to_remote someday
		link_to text, url
	end

    # sorting helpers
    def sort_td_class_helper(param, classes=[])
		classes = classes.gsub(',', ' ').split(/\s+/) unless classes.is_a? Array
		classes << 'sortup' if params[:sort] == param
		classes << 'sortdown' if params[:sort] == param + '_reverse'
		return 'class="' + classes.join(" ") + '"'
    end

    def sort_link(text, param, update, controller, action, refresh = nil)
        key = param
        key += "_reverse" if params[:sort] == param
		params[:action] = action
		if controller.nil?
            url = {
				:action => action,
				:params => params.merge({:sort => key, :page => nil, :refresh => nil}),
			}
			href =  url_for(
				:action => action,
                :params => params.merge({:sort => key, :page => nil, :refresh => nil})
            )
        else
            url = {
				:controller => controller,
				:action => action,
				:params => params.merge({:sort => key, :page => nil, :refresh => nil}),
			}
			href =  url_for(
                :controller => controller,
				:action => action,
                :params => params.merge({:sort => key, :page => nil, :refresh => nil})
            )
        end
        options = {
            :url => url,
            :update => update,
			:method => :get,
        }
        html_options = {
            :title => "Sort by this field",
            :href => href,
        }
        link_to_remote(text, options, html_options)
    end
    
    def filter_link(text, param, value, update, controller, action)
		my_filter = param+":"+value
		params[:action] = action

		filter = params[:filter] ? params[:filter] : ''
		filters = filter.split(',')
		
		# the link will remove a different filter on the same parameter if it's currently applied
		f_found = nil
		filters.each do |f|
			(fparam, fvalue) = f.split(':')
			f_found = f if (fparam == param and fvalue != value)
		end
		filters.delete_if{|f| f_found and f_found == f}
		
		# the link will remove this filter if it's currently applied
		if filters.include?(my_filter)
			filters.delete_if{|f| f == my_filter}
			klass = "button pressed"
			action_klass = "button"
			tip = "Remove filter"
		# the link will apply this filter if it's not currently applied
		else
			filters << my_filter
			klass = "button"
			action_klass = "button pressed"
			tip = "Filter by #{param}=#{value}"
		end
		filter = filters.join(',')
        
        url = {
			:action => action,
			:params => params.merge({:filter => filter, :sort => params[:sort], :page => nil, :refresh => nil}),
		}
        url[:controller] = controller unless controller.nil?
		
		href =  url_for(url)

        options = {
            :url => url,
            :update => update,
			:method => :get,
			:before => "$(this).className='#{action_klass}'",
        }
		
        html_options = {
            :title => tip,
            :href => href,
            :class => klass,
        }
        
		text = "<span>#{text}</span>"
        link_to_remote(text, options, html_options)
    end
    
    def no_filter_link(text, update, controller, action)
		params[:action] = action
		
		if params[:filter].blank?
			klass = "button pressed"
			action_klass = "button"
			tip = "Showing all records"
	        html_options = {
	            :title => tip,
	            :class => klass,
	        }
	        
			text = "<span>#{text}</span>"
	        link_to(text, '#', html_options)
		else
			klass = "button"
			action_klass = "button pressed"
			tip = "Remove all filters"
	        url = {
				:action => action,
				:params => params.merge({:filter => nil, :sort => params[:sort], :page => nil, :refresh => nil}),
			}
	        url[:controller] = controller unless controller.nil?
			
			href =  url_for(url)
	
	        options = {
	            :url => url,
	            :update => update,
				:method => :get,
				:before => "$(this).className='#{action_klass}'",
	        }
			
	        html_options = {
	            :title => tip,
	            :href => href,
	            :class => klass,
	        }
	        
			text = "<span>#{text}</span>"
	        link_to_remote(text, options, html_options)
		end
    end

	def show_all_link(text)
		no_filter_link(text, nil, nil, :list)
	end

	def filter_by_owner_id_link(text, value)
		filter_link(text, 'owner_id', value, nil, nil, :list)
	end

	def filter_by_status_link(text, value)
		filter_link(text, 'status', value, nil, nil, :list)
	end
	
	def filter_by_state_link(text, value)
		filter_link(text, 'state', value, nil, nil, :list)
	end
	
	def filter_by_user_id_link(text, value)
		filter_link(text, 'user_id', value, nil, nil, :list)
	end
	
	def filter_by_server_id_link(text, value)
		filter_link(text, 'server_id', value, nil, nil, :list)
	end

	def selectable_check_box_tag(name, value, checked, options = {})
		html_options = options.merge({
			:onclick => "select_parent_element($(this));",
            :class => "selectable_check_box"
		})
		check_box_tag name, value, checked, html_options
	end

    def select_all_check_box(name, options = {})
        field_tag = check_box_tag name, '1', false, options
        observe_tag = observe_field name,
            :function => "if (value == 1) Selectable.check_all(); else Selectable.uncheck_all();"
        field_tag + observe_tag
    end

	def better_check_box_tag(name, value, checked, klass, options = {})
		html_options = options.merge({
			:onclick => "select_parent_element($(this));",
            :class => "#{klass} selectable_check_box"
		})
		check_box_tag name, value, checked, html_options
	end

    def better_select_all_check_box(name, klass, options = {})
        field_tag = check_box_tag name, '1', false, options
        observe_tag = observe_field name,
            :function => "if (value == 1) Selectable.check_all('.#{klass}'); else Selectable.uncheck_all('.#{klass}');"
        field_tag + observe_tag
    end

    def time_and_time_ago(value)
        time = h(value)
        unless value.blank?
            time += ' - ' + time_ago_in_words(value) + ' ago'
        end
        return time
    end

    def time_ago(value)
        time = h(value)
        unless value.blank?
            time = time_ago_in_words(value) + ' ago'
        end
        return time
    end

    def provider_account_controller_path(provider_account, controller_name)
    end

    def menu_link_to_controller (controller_name, provider_account, action = 'index')
        if controller_name.index(controller.controller_name).nil?
            div_class = 'menu-item'
        else
            div_class = 'menu-item-selected'
        end
        link_options = { :class => 'menu-link' }
        if provider_account.nil?
            url = url_for(:controller => controller_name, :action => action)
        else
            url = url_for([provider_account, controller_name.sub('/','')])
        end
        name = controller_name.gsub('/','_').titleize
        "<div class='#{div_class}'>" + link_to(name, url, link_options) + "</div>"
    end

    def menu_link_to (name, url, html_options = {})
        div_class = 'menu-item'
        html_options.merge!({ :class => 'menu-link' })
        "<div class='#{div_class}'>" + link_to(name, url, html_options) + "</div>"
    end

    def menu_link_to_remote (name, options, html_options)
        div_class = 'menu-item'
        html_options.merge!({ :class => 'menu-link' })
        "<div class='#{div_class}'>" + link_to_remote(name, options, html_options) + "</div>"
    end

    def main_title (page_title = '')
        title = ''
        unless @provider_account.nil?
            title += link_to(h(@provider_account.name), @provider_account) + ' / '
        end
        if @security_group.nil?
            title += 'All Security Groups / '
        else
            title += link_to(h(@security_group.name), @security_group) + ' / '
        end
        title += page_title
        return title
    end

    def show_hide_link (name, klass)
        link_to_function name, "$$('.hidable').each(function(d) { d.hide() }); $$('.#{klass}').each(function(d) { Effect.toggle(d, 'appear') });"
    end

    def error_messages_for_multiple_objects(object_names, options = {})
		options = options.symbolize_keys
		object_name_for_error = object_names[0]
		all_errors = ""
		all_errors_count = 0
		object_names.each do |object_name|
			object = instance_variable_get("@#{object_name}")
			if object && !object.errors.empty?
				object_errors = object.errors.full_messages.collect {
					|msg| content_tag("li", msg)
				}
				all_errors_count += object_errors.size
				all_errors << "#{object_errors}"
			end
		end

		if all_errors_count > 0
			tag = content_tag("div",
			content_tag(
				options[:header_tag] || "h2",
				"#{pluralize(all_errors_count, "error")} prohibited this" \
				" #{object_name_for_error.to_s.gsub("_", " ")} from being saved"
				) +
				content_tag("p", "There were problems with the following fields:") +
				content_tag("ul", all_errors),
				"id" => options[:id] || "errorExplanation",
				"class" => options[:class] || "errorExplanation"
			)
		else
			""
		end
	end

	def expand_subordinate_link(link_text, prefix, model, subordinate, suffix)
		unless subordinate.is_a?(Symbol) or subordinate.is_a?(String)
			raise ArgumentError, "subordinate must be a symbol or string!"
		end

		subordinate = subordinate.to_sym unless subordinate.is_a? Symbol
		div_id = "#{prefix}_#{model.id}_#{subordinate.to_s}"
		div_id += "_#{suffix}" unless suffix.blank?

		url = polymorphic_url([model, subordinate])
    	options = {
            :url => url,
            :method => :get,
            :success => "
				$('#{prefix}_#{model.id}_expand_#{subordinate.to_s}').hide();
				$('#{prefix}_#{model.id}_compress_#{subordinate.to_s}').show();
				$('#{div_id}').show();
			",
		}
		html_options = {
			:title => "Expand list of #{subordinate.to_s} for '#{model.name}'",
            :href => url,
            :method => :get,
		}
		link_to_remote link_text, options, html_options
	end

	def expand_subordinate_image_link(prefix, model, subordinate, image=nil, width=nil, height=nil, suffix=nil)
		image ||= 'expand.png'
		options = {}
		options[:class] = 'control-icon'
		options[:title] = "Show list of #{subordinate.to_s} for #{model.name}"
		options[:alt] = 'expand'
		options[:width] = width unless width.nil?
		options[:height] = height unless height.nil?

		expand_subordinate_link(
			image_tag(image, options), prefix, model, subordinate, suffix
		)
	end

	def hide_subordinate_link(link_text, prefix, model, subordinate, suffix=nil)
		unless subordinate.is_a?(Symbol) or subordinate.is_a?(String)
			raise ArgumentError, "subordinate must be a symbol or string!"
		end
		
		div_id = "#{prefix}_#{model.id}_#{subordinate.to_s}"
		div_id += "_#{suffix}" unless suffix.blank?
		
		link_to_function(
			link_text,
			"
				$('#{prefix}_#{model.id}_compress_#{subordinate.to_s}').hide();
				$('#{prefix}_#{model.id}_expand_#{subordinate.to_s}').show();
				$('#{div_id}').innerHTML = '';
			"
		)
	end

	def hide_subordinate_image_link(prefix, model, subordinate, image=nil, width=nil, height=nil, suffix=nil)
		image ||= 'contract.png'
		options = {}
		options[:class] = 'control-icon'
		options[:title] = "Hide list of #{subordinate.to_s} for #{model.name}"
		options[:alt] = 'expand'
		options[:width] = width unless width.nil?
		options[:height] = height unless height.nil?

		hide_subordinate_link(
			image_tag(image, options), prefix, model, subordinate, suffix
		)
	end

	def self.setup_methods_for_subordinate(prefix, subordinate, image=nil, width=nil, height=nil, suffix=nil)
		unless subordinate.is_a?(Symbol) or subordinate.is_a?(String)
			raise ArgumentError, "subordinate must be a symbol or string!"
		end

		define_method("expand_#{subordinate.to_s}_link") do |link_text, model|
			self.send("expand_subordinate_link", link_text, prefix, model, subordinate, suffix)
		end

		define_method("expand_#{subordinate.to_s}_image_link") do |model|
			self.send("expand_subordinate_image_link", prefix, model, subordinate, (!image.nil?() ? image + '.png' : nil), width, height, suffix)
		end

		define_method("hide_#{subordinate.to_s}_link") do |link_text, model|
			self.send("hide_subordinate_link", link_text, prefix, model, subordinate, suffix)
		end

		define_method("hide_#{subordinate.to_s}_image_link") do |model|
			self.send("hide_subordinate_image_link", prefix, model, subordinate, (!image.nil?() ? image + '-hide.png' : nil), width, height, suffix)
		end
	end
	
    def protocol_select(f, name, options={}, html_options={})
		f.collection_select(name, PROTOCOLS, :label, :value, options, html_options)
    end
    
    def close_redbox_link(text, redbox)
        link_to_function text, "$('#{redbox}').hide(); $('#{redbox}').innerHTML = '';"
    end
end
