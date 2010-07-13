# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false
#
#config.after_initialize do
#	require 'application' unless Object.const_defined?(:ApplicationController)
#	LoggedExceptionsController.class_eval do
#		# set the same session key as the app
#		session :session_key => APP_CONFIG['settings']['session_key']
#      
#		# include any custom auth modules you need
#		include AuthenticatedSystem
#		include RoleRequirementSystem
#      
#		before_filter :login_required
#		require_role  :admin
#      
#		# optional, sets the application name for the rss feeds
#		self.application_name = APP_CONFIG['settings']['name']
#	end
#end
