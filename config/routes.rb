ActionController::Routing::Routes.draw do |map|
	map.resources :dashboard, :only => [ :index ]
	map.resources :providers do |provider|
		provider.resources :regions, :controller => 'provider/regions',
			:only => [ :index ]
		provider.resources :services, :controller => 'parent/services',
			:collection => { :list => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
	end
	map.resources :regions do |region|
		region.resources :zones, :controller => 'region/zones',
			:only => [ :index ]
	end
	map.resources :provider_accounts,
	    :collection => { :list => :any, :control => :post } do |provider_account|
		provider_account.resources :instances, :controller => 'parent/instances',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list ]
		provider_account.resources :servers, :controller => 'parent/servers',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new ]
		provider_account.resources :auto_scaling, :controller => 'provider_account/auto_scaling',
			:collection => { :list => :any },
			:only => [ :index, :list ]
		provider_account.resources :launch_configurations, :controller => 'provider_account/launch_configurations',
			:collection => { :list => :get },
			:only => [ :new, :create ]
		provider_account.resources :auto_scaling_groups, :controller => 'provider_account/auto_scaling_groups',
			:collection => { :list => :any }
		provider_account.resources :server_images, :controller => 'provider_account/server_images',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create ]
		provider_account.resources :security_groups, :controller => 'provider_account/security_groups',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		provider_account.resources :firewall_rules, :controller => 'provider_account/firewall_rules',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		provider_account.resources :addresses, :controller => 'parent/addresses',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create ]
		provider_account.resources :volumes, :controller => 'parent/volumes',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		provider_account.resources :snapshots, :controller => 'parent/snapshots',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		provider_account.resources :users, :controller => 'provider_account/users',
			:only => [ :index, :create, :destroy ]
		provider_account.resources :services, :controller => 'parent/services',
			:collection => { :list => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		provider_account.resources :dns_hostnames,
			:controller => 'provider_account/dns_hostnames',
			:except => [ :edit, :update, :new ],
			:member => { :acquire => :post },
			:collection => { :list => :any } do |hostname|
				hostname.resources :dns_leases,
					:controller => 'provider_account/dns_leases',
					:collection => { :release => :delete },
					:except => [ :destroy, :edit, :new, :update, :create ]
			end
		provider_account.resources :dns_leases, :controller => 'provider_account/dns_leases',
			:collection => { :release => :delete, :list => :any  }, :except => [ :destroy, :edit, :new, :update, :create ]
		provider_account.resources :stats, :controller => 'provider_account/stats',
			:only => [ :index ]
########
		provider_account.resources :clusters
		provider_account.resources :provider_account_parameters
		provider_account.resources :events
#		provider_account.resources :instance_list_readers
		provider_account.resources :in_messages
		provider_account.resources :out_messages
		provider_account.resources :publishers
		provider_account.resources :key_pairs
	end

	# services
	map.resources :service_types,     :collection => { :list => :any },
		:controller => 'service/types'
	map.resources :service_providers,
		:collection => { :list => :any, :auto_complete_for_service_provider_server_name => :any },
		:controller => 'service/providers'
	map.resources :service_overrides, :collection => { :list => :any },
		:controller => 'service/overrides'
  
	# instances
	map.resources :instances,
		:collection => { :list => :any },
		:member => { :reboot => :put, :terminate => :post },
		:only => [ :index, :show, :edit, :update ] do |instance|
			instance.resource :servers,
				:controller => 'parent/servers',
				:only => [ :new, :create ]
			instance.resources :dns_leases, :controller => 'instance/dns_leases', :only => [ :release, :show ],
				:collection => { :release => :delete }, :member => { :release => :delete }
			instance.resources :dns_hostnames, :controller => 'instance/dns_hostnames', :only => [ :acquire, :show ],
				:collection => { :acquire => :post }, :member => { :acquire => :post }
			instance.resources :instance_resources, :controller => 'instance/instance_resources',
				:member => { :attach => :get, :detach => :get },
				:collection => { :list => :any },
				:only => [ :create, :destroy, :update ]
			instance.resources :addresses, :controller => 'instance/addresses',
				:collection => { :list => :any },
				:only => [ :index, :list, :create, :destroy, :update ]
			instance.resources :volumes, :controller => 'instance/volumes',
				:collection => { :list => :any },
				:only => [ :index, :list, :create, :destroy, :update ]
    end

	# auto scaling launch configurations
	map.resources :launch_configurations,
		:member => { :associate => :put, :disable => :post, :activate => :post },
		:only => [ :associate, :show, :edit, :destroy, :update ]
		
	# auto scaling group
	map.resources :auto_scaling_groups,
		:member => { :disable => :post, :activate => :post } do |group|
		group.resources :instances, :controller => 'parent/instances',
			:collection => { :list => :any, :control => :any },
			:only => [ :index ]
		group.resources :triggers, :controller => 'auto_scaling_group/triggers',
			:collection => { :list => :any }
	end
	
	# auto scaling triggers
	map.resources :auto_scaling_triggers,
		:member => { :activate => :post, :disable => :post },
		:only => [ :activate, :disable, :destroy ]

	# cloud resources - addresses, volumes, snapshots		
	map.resources :cloud_resources do |cloud_resource|
		cloud_resource.resources :clusters,
			:controller => 'cloud_resource/clusters',
			:only => [ :new, :create, :destroy ]
	end
	map.cloud_resources_cluster_ac '/cloud_resource_cluster_ac', :controller => 'cloud_resource/clusters',
		:action => 'auto_complete_for_cluster_id'
	
	# addresses
	map.resources :cloud_addresses, :collection => { :list => :any }, :only => [ :index, :update ]

	# volumes
	map.resources :cloud_volumes, :collection => { :list => :any }, :only => [ :index, :update ]

	# snapshots
	map.resources :cloud_snapshots, :collection => { :list => :any }, :only => [ :index, :update ]

	# server images
    map.resources :server_images,
   		:collection => { :list => :any },
		:only => [  :index, :update ] do |server_image|
		server_image.resources :servers
	end

  	# security groups
  	map.resources :security_groups,
		:collection => { :auto_complete_for_firewall_rule_id => :any } do |security_group|
		security_group.resources :firewall_rules, :controller => 'security_group/firewall_rules',
			:only => [ :create, :destroy ]
		security_group.resources :instances, :controller => 'security_group/instances',
			:collection => { :list => :any },
			:only => [ :index, :list ]
		security_group.resources :servers, :controller => 'parent/servers',
			:collection => { :list => :any },
			:only => [ :index, :list ]
  	end
    
	# firewall rules
	map.resources :firewall_rules do |firewall_rule|
		firewall_rule.resources :security_groups, :controller => 'firewall_rule/security_groups',
			:collection => { :list => :any },
			:only => [ :index, :list, :create, :destroy ] 
	end

	map.resources :dns_leases, :member => { :release => :delete }
	map.resources :dns_hostnames

########
	map.hostname_ac '/dns_hostname_ac',
		:controller => 'servers', :action => 'auto_complete_for_dns_hostname_id'
	map.provider_account_dns_hostname_ac '/provider_account_dns_hostname_ac',
		:controller => 'provider_account/dns_hostnames', :action => 'auto_complete_for_dns_hostname_id'
	map.server_dns_hostname_ac '/server_dns_hostname_ac',
		:controller => 'server/dns_hostnames', :action => 'auto_complete_for_dns_hostname_id'
	map.update_provider_accounts '/update_provider_accounts',
		:controller => 'provider_accounts', :action => 'update_all'
########

	# handle provider account messaging parameters
	map.provider_account_messaging '/provider_accounts/:provider_account_id/messaging',
		:controller => 'provider_account/messaging', :action => 'update',
		:conditions => { :method => :post }

	# publishers
	map.resources :publishers, :member => { :verify => :any, :run => :any }

	# handle provider_account admins
	map.provider_account_user_ac '/provider_account_user_ac', :controller => 'provider_accounts', :action => 'auto_complete_for_user_id'

	# handle cluster admins
	map.cluster_user_ac '/cluster_user_ac', :controller => 'clusters', :action => 'auto_complete_for_user_id'

  	# clusters
  	map.resources :clusters,
		:collection => { :list => :any } do |cluster|
		cluster.resources :instances, :controller => 'parent/instances',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list ]
		cluster.resources :servers, :controller => 'parent/servers',
			:member => { :start => :post },
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :new, :create, :destroy ]
		cluster.resources :addresses, :controller => 'parent/addresses',
			:collection => { :list => :any }, :only => [ :index, :list ]
		cluster.resources :volumes, :controller => 'parent/volumes',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
		cluster.resources :snapshots, :controller => 'parent/snapshots',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :new, :create, :destroy ]
        cluster.resources :cluster_parameters
        cluster.resources :users, :controller => 'cluster/users',
			:only => [ :index, :create, :destroy ]
		cluster.resources :dns_hostnames, :controller => 'cluster/dns_hostnames', :except => [ :edit, :update, :new ],
			:member => { :acquire => :post }, :collection => { :list => :any }  do |hostname|
				hostname.resources :dns_leases, :controller => 'cluster/dns_leases',
					:collection => { :release => :delete }, :except => [ :destroy, :edit, :new, :update, :create ]
			end
		cluster.resources :dns_leases, :controller => 'cluster/dns_leases',
			:collection => { :release => :delete, :list => :any  }, :except => [ :destroy, :edit, :new, :update, :create ]
		cluster.resources :stats, :controller => 'cluster/stats', :only => [ :index ]
	end

	# provider_account_parameters
	map.resources :provider_account_parameters, :collection => { :sort => :post }

	# cluster parameters
	map.resources :cluster_parameters, :collection => { :sort => :post }

	# servers
	map.resources :servers,
		:collection => { :list => :any },
		:only => [ :index, :show, :edit, :update ] do |server|
		server.resources :instances, :controller => 'parent/instances',
			:collection => { :list => :any, :control => :any },
			:only => [ :index ]
		server.resources :server_parameters
		server.resources :resource_bundles, :controller => 'server/resource_bundles',
			:member => { :make_default => :post, :start => :post },
			:collection => { :sort => :post },
			:only => [ :index, :list, :sort, :create, :destroy, :update, :make_default ]
		server.resources :dns_hostnames, :controller => 'server/dns_hostnames', :except => [ :edit, :update, :new ],
			:member => { :acquire => :post, :assign => :post, :unassign => :delete }, :collection => { :list => :any }  do |hostname|
				hostname.resources :dns_leases, :controller => 'server/dns_leases',
					:collection => { :release => :delete }, :except => [ :destroy, :edit, :new, :update, :create ]
		end
		server.resources :dns_leases, :controller => 'server/dns_leases',
			:collection => { :release => :delete, :list => :any }, :except => [ :destroy, :edit, :new, :update, :create ]
		server.resources :server_tasks, :controller => 'parent/server_tasks',
			:member => { :run => :get },
			:collection => { :list => :any }
		server.resources :operations, :controller => 'parent/operations',
			:collection => { :list => :any, :control => :any },
			:only => [ :index, :list, :show ]
		server.resources :security_groups, :controller => 'server/security_groups', :only => [ :destroy ]
	end
		
	# server tasks
	map.resources :server_tasks, :controller => 'server_tasks', :only => [ :update ]

	# resource_bundles
	map.resources :resource_bundles do |resource_bundle|
		resource_bundle.resources :server_resources, :controller => 'resource_bundle/server_resources',
				:only => [ :new, :create, :destroy, :update ]
		resource_bundle.resources :server_addresses, :controller => 'resource_bundle/server_resources',
			:only => [ :new, :create, :destroy, :update ]
		resource_bundle.resources :server_volumes, :controller => 'resource_bundle/server_resources',
			:only => [ :new, :create, :destroy, :update ]
	end

	map.resources :server_parameters, :collection => { :sort => :post }
    map.resources :operations, :has_many => [ :operation_logs ]

	map.show_server_server_user_data '/server/:id/user_data', :controller => 'server/user_data', :action => 'show'

    # server profiles
    map.resources :server_profiles, :has_many => [ :server_profile_revisions ]
	map.resources :server_profile_revisions, :has_many => [ :server_profile_revision_parameters ]
	map.show_server_profile_revision_user_data '/server_profile_revision/:id/user_data', :controller => 'server_profile_revision/user_data', :action => 'show'
	map.resources :server_profile_revision_parameters, :collection => { :sort => :post }

	# handling instances
	map.show_instance_console_output '/instances/:id/console_output', :controller => 'instance/console_output', :action => 'show'
#    map.attach_instance_volume '/instances/:id/attach_volume', :controller => 'instances', :action => 'attach_volume'
#    map.associate_instance_address '/instances/:id/associate_address', :controller => 'instances', :action => 'associate_address'

	# system-wide resources
	map.resources :events, :collection => { :list => :any }, :only => [ :index ]
	map.resources :in_messages, :controller => 'in_messages', :collection => { :list => :any }, :only => [ :index, :list ]
	map.resources :out_messages, :controller => 'out_messages', :collection => { :list => :any }, :only => [ :index, :list ]
	map.resources :daemons,
		:collection => { :list => :any, :control => :any },
		:only => [ :index ]

	# logout
	map.logout 				'/logout',	:controller => 'sessions', :action => 'destroy'
	# login
	map.login 				'/login',	:controller => 'sessions', :action => 'new'
	map.login_with_openid	'/login_with_openid',	:controller => 'openid_sessions', :action => 'new'
	# signup
	map.signup				'/signup',	:controller => 'user/profiles', :action => 'new'
	map.beta_signup			'/signup/:invitation_token',	:controller => 'user/profiles', :action => 'new'
	map.openid_signup		'/openid_signup',	:controller => 'openid_sessions', :action => 'index'
	map.beta_openid_signup	'/openid_signup/:invitation_token', :controller => 'openid_sessions', :action => 'index'
	map.ldap_signup			'/ldap_signup',	:controller => 'user/ldap_accounts', :action => 'new'
	map.beta_ldap_signup	'/ldap_signup/:invitation_token', :controller => 'ldap_sessions', :action => 'new'
	# activate, forgot, reset
	map.activate			'/activate/:activation_code', :controller => 'user/activations',
		:action => 'activate', :activation_code => nil
	map.resend_activation 	'/resend_activation', :controller => 'user/activations', :action => 'new'
	map.forgot_password 	'/forgot_password', :controller => 'user/passwords', :action => 'new'
	map.reset_password 		'/reset_password/:id', :controller => 'user/passwords', :action => 'edit', :id => nil

	# admin namespace
	map.namespace :admin do |admin|
		admin.resources :controls
		admin.resources :invite_actions
		admin.resources :invites
		admin.resources :mailings
		admin.resources :states
		admin.resources :users do |users|
			users.resources :roles
			users.resources :provider_accounts
		end
	end
	map.list_users	'/admin/users/list', :controller => 'admin/users', :action => 'list'
	map.activate_admin_user '/admin/user/:id/activate', :controller => 'admin/users', :action => 'update'
	map.enable_admin_user '/admin/user/:id/enable', :controller => 'admin/states', :action => 'update'
	map.disable_admin_user '/admin/user/:id/disable', :controller => 'admin/states', :action => 'destroy'

	# user namespace
	map.namespace :user do |user|
		user.resources :activations
		user.resources :invitations
		user.resources :openid_accounts
		user.resources :ldap_accounts
		user.resources :passwords
		user.resources :profiles do |profiles|
			profiles.resources :password_settings
		end
	end

	# system logs
	map.resources :system_logs, :controller => 'system_logs', :collection => { :list => :any },	:only => [ :index ]

	# activity logs
	map.resources :audit_logs, :controller => 'parent/audit_logs', :collection => { :list => :any }, :only => [ :index ]

	# session handling
	map.resource  :session
	map.resource  :openid_session
	map.resource  :ldap_session
	map.resources :members
	
	# default routes, exceptions and 404s
	map.root :controller => 'dashboard', :action => 'index'
	map.logged_exceptions "logged_exceptions/:action/:id", :controller => "logged_exceptions"
	map.connect '*path', :controller => 'four_oh_fours'
end
