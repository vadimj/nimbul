# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'ldap_connect'
require_dependency 'provider_account'
require_dependency 'security_group'

class ApplicationController < ActionController::Base
	include SortableTable::App::Controllers::ApplicationController
	layout "application"
	# LDAP functions
	include LDAP
	# AuthenticatedSystem must be included for RoleRequirement, and is provided by installing acts_as_authenticates and running 'script/generate authenticated account user'.
	include AuthenticatedSystem
	# You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
	include RoleRequirementSystem
	include ExceptionLoggable

	helper :all # include all helpers, all the time

	# See ActionController::RequestForgeryProtection for details
	# Uncomment the :secret if you're not using the cookie session store
	protect_from_forgery :secret => APP_CONFIG['settings']['secret']

	# See ActionController::Base for details
	# Uncomment this to filter the contents of submitted sensitive data parameters
	# from your application log (in this case, all fields with names like "password").
	filter_parameter_logging :password, :password_confirmation, :old_password
	filter_parameter_logging :aws_access_key, :aws_secret_key, :ssh_master_key
	filter_parameter_logging :aws_access_key_ui, :aws_secret_key_ui, :ssh_master_key_ui

	before_filter :set_user_time_zone, :set_ssl
	after_filter :store_location, :except => [ :new, :edit ]
	after_filter :discard_flash_if_xhr

	def set_ssl
		request.env['HTTPS'] = 'on' if ENV['RAILS_ENV'] == 'production'
	end

	# Change to the location of your contact form
	def contact_site
		root_path
	end

	def nested_layout
		"default"
	end

	def in_beta?
		APP_CONFIG['settings']['in_beta']
	end

	private

    def cache(key)
        unless output = CACHE.get(key)
            output = yield
            CACHE.set(key, output, 1.hour)
        end
        return output
    end

	def set_user_time_zone
		Time.zone = current_user.time_zone if logged_in?
	end

	def call_rake(task, options = {})
		options[:rails_env] = Rails.env
		args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
		system "/usr/bin/rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
	end

    def provider_accounts_for_user(user=current_user)
        if current_user.has_role?("admin")
			provider_accounts = ProviderAccount.find(:all, :include => [ :clusters ], :order => :name)
		else
        	provider_accounts = current_user.provider_accounts
        	provider_accounts.sort!{ |a,b| a.name.downcase <=> b.name.downcase }
		end
		return provider_accounts
    end

    def clusters_for_user(user=current_user)
        clusters = current_user.clusters
        clusters.sort!{ |a,b| a.name.downcase <=> b.name.downcase }
		return clusters
    end

    # auto_complete_for :user, :login
    def auto_complete_for_user_id(options = {})
        @search = params[:user][:id]
        conditions = [ "LOWER(login) LIKE ? OR LOWER(name) LIKE ? OR LOWER(email) LIKE ?" ]
        conditions << ('%' + @search + '%')
        conditions << ('%' + @search + '%')
        conditions << ('%' + @search + '%')
        order = 'login ASC'
        find_options = {
            :conditions => conditions,
            :order => order,
            :limit => 10 }.merge!(options)

        @users = User.find(:all, find_options)

        #render :inline => "<%= auto_complete_result @users, 'login' %>"
        #tags = "<%= content_tag(:ul, @users.map { |user| content_tag(:li, user_name_login_email_id(user), :onclick => 'submit_user_id(\"'+user.id.to_s+'\");') }) %>"
        tags = "<%= content_tag(:ul, @users.map{ |user| content_tag(:li, user_name_login_email_id(user, @search)) }) %>"
        render :inline => tags
    end

	# support for polymorphic controllers
	class_inheritable_accessor :parents
		
	def self.parent_resources(*parents)
		self.parents = parents
	end

	protected

	def discard_flash_if_xhr
		flash.discard if request.xhr?
	end
	
	def parent
		return @parent if @parent
		@parent = parent_class && parent_class.find_by_id(parent_id(parent_type))
		instance_variable_set("@#{parent_type}", @parent) # Layouts usually want a @user, @item etc
	end

	def parent_id(parent)
		request.path_parameters["#{ parent }_id"]
	end

	def parent_type
		self.class.parents.detect { |parent| parent_id(parent) }
	end

	def parent_class
		parent_type && parent_type.to_s.classify.constantize
	end
   
	def parent_object
		parent_class && parent_class.find_by_id(parent_id(parent_type))
	end
	
	# support for json errors
	def errors_to_json(model)
		return ModelError.new({
			:model => model,
			:error => model.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('\n'),
		})
	end
end
