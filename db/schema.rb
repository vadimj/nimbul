# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101222210343) do

  create_table "addresses", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "public_ip"
    t.string   "instance_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.boolean  "is_enabled",          :default => true
  end

  add_index "addresses", ["name"], :name => "index_addresses_on_name"
  add_index "addresses", ["public_ip"], :name => "index_addresses_on_public_ip"

  create_table "audit_logs", :force => true do |t|
    t.string   "provider_account_name"
    t.integer  "provider_account_id"
    t.string   "cluster_name"
    t.integer  "cluster_id"
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.string   "auditable_name"
    t.string   "author_login"
    t.integer  "author_id"
    t.string   "summary"
    t.text     "changes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "server_name"
    t.integer  "server_id"
  end

  add_index "audit_logs", ["auditable_id", "auditable_type"], :name => "index_audit_logs_on_auditable_id_and_auditable_type"
  add_index "audit_logs", ["auditable_name"], :name => "index_audit_logs_on_auditable_name"
  add_index "audit_logs", ["author_id"], :name => "index_audit_logs_on_author_id"
  add_index "audit_logs", ["author_login"], :name => "index_audit_logs_on_author_login"
  add_index "audit_logs", ["cluster_id"], :name => "index_audit_logs_on_cluster_id"
  add_index "audit_logs", ["cluster_name"], :name => "index_audit_logs_on_cluster_name"
  add_index "audit_logs", ["provider_account_id"], :name => "index_audit_logs_on_provider_account_id"
  add_index "audit_logs", ["provider_account_name"], :name => "index_audit_logs_on_provider_account_name"
  add_index "audit_logs", ["server_id"], :name => "index_audit_logs_on_server_id"
  add_index "audit_logs", ["server_name"], :name => "index_audit_logs_on_server_name"
  add_index "audit_logs", ["summary"], :name => "index_audit_logs_on_summary"

  create_table "auto_scaling_groups", :force => true do |t|
    t.integer  "launch_configuration_id"
    t.integer  "provider_account_id"
    t.string   "name",                    :limit => 256,                         :null => false
    t.integer  "min_size"
    t.integer  "max_size"
    t.integer  "desired_capacity"
    t.integer  "cooldown"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                                  :default => "disabled"
  end

  add_index "auto_scaling_groups", ["launch_configuration_id"], :name => "index_lc_id_on_asg"
  add_index "auto_scaling_groups", ["provider_account_id"], :name => "index_pa_id_on_asg"

  create_table "auto_scaling_groups_instances", :id => false, :force => true do |t|
    t.integer "auto_scaling_group_id"
    t.integer "i_id"
  end

  add_index "auto_scaling_groups_instances", ["auto_scaling_group_id"], :name => "index_asg_id_on_asgi"
  add_index "auto_scaling_groups_instances", ["i_id"], :name => "index_i_id_on_asgi"

  create_table "auto_scaling_groups_load_balancers", :id => false, :force => true do |t|
    t.integer "auto_scaling_group_id"
    t.integer "load_balancer_id"
  end

  add_index "auto_scaling_groups_load_balancers", ["auto_scaling_group_id"], :name => "asglb_asg_id_index"
  add_index "auto_scaling_groups_load_balancers", ["load_balancer_id"], :name => "asglb_lb_id_index"

  create_table "auto_scaling_groups_zones", :id => false, :force => true do |t|
    t.integer "auto_scaling_group_id"
    t.integer "zone_id"
  end

  add_index "auto_scaling_groups_zones", ["auto_scaling_group_id"], :name => "asgaz_asg_id_index"
  add_index "auto_scaling_groups_zones", ["zone_id"], :name => "asgaz_az_id_index"

  create_table "auto_scaling_triggers", :force => true do |t|
    t.integer  "auto_scaling_group_id"
    t.integer  "provider_account_id"
    t.string   "name",                         :limit => 64,                               :null => false
    t.integer  "period"
    t.string   "lower_threshold"
    t.string   "upper_threshold"
    t.integer  "breach_duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "lower_breach_scale_increment"
    t.string   "upper_breach_scale_increment"
    t.string   "state",                                      :default => "disabled"
    t.string   "measure_name",                               :default => "CPUUtilization"
    t.string   "statistic",                                  :default => "Average"
    t.string   "unit"
  end

  add_index "auto_scaling_triggers", ["auto_scaling_group_id"], :name => "index_asg_id_on_asgt"
  add_index "auto_scaling_triggers", ["provider_account_id"], :name => "index_pa_id_on_asgt"

  create_table "block_device_mappings", :force => true do |t|
    t.integer  "launch_configuration_id"
    t.string   "virtual_name"
    t.string   "device_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "block_device_mappings", ["launch_configuration_id"], :name => "index_block_device_mappings_on_launch_configuration_id"

  create_table "cloud_resources", :force => true do |t|
    t.string   "type"
    t.integer  "provider_account_id"
    t.integer  "zone_id"
    t.string   "cloud_id"
    t.string   "name"
    t.string   "state",                    :default => "unknown"
    t.datetime "create_time"
    t.datetime "update_time"
    t.integer  "size"
    t.string   "parent_cloud_id"
    t.boolean  "is_enabled",               :default => true
    t.text     "meta_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_id"
    t.string   "description"
    t.integer  "server_resources_count",   :default => 0
    t.integer  "instance_resources_count", :default => 0
    t.string   "progress"
    t.string   "attachment_state"
    t.string   "attach_time"
    t.datetime "start_time"
    t.integer  "instance_id"
    t.string   "cloud_instance_id"
  end

  add_index "cloud_resources", ["description"], :name => "index_cloud_resources_on_description"
  add_index "cloud_resources", ["owner_id"], :name => "index_cloud_resources_on_owner_id"
  add_index "cloud_resources", ["provider_account_id", "cloud_id"], :name => "index_cloud_resources_on_provider_account_id_and_cloud_id", :unique => true
  add_index "cloud_resources", ["provider_account_id", "cloud_instance_id"], :name => "index_crs_on_paid_and_ciid"
  add_index "cloud_resources", ["provider_account_id", "instance_id"], :name => "index_cloud_resources_on_provider_account_id_and_instance_id"
  add_index "cloud_resources", ["provider_account_id", "parent_cloud_id"], :name => "index_cloud_resources_on_provider_account_id_and_parent_cloud_id"
  add_index "cloud_resources", ["provider_account_id", "type"], :name => "index_cloud_resources_on_provider_account_id_and_type"
  add_index "cloud_resources", ["zone_id"], :name => "index_cloud_resources_on_zone_id"

  create_table "cloud_resources_clusters", :id => false, :force => true do |t|
    t.integer "cloud_resource_id"
    t.integer "cluster_id"
  end

  add_index "cloud_resources_clusters", ["cloud_resource_id"], :name => "index_cloud_resources_clusters_on_cloud_resource_id"
  add_index "cloud_resources_clusters", ["cluster_id"], :name => "index_cloud_resources_clusters_on_cluster_id"

  create_table "cluster_parameters", :force => true do |t|
    t.integer  "cluster_id"
    t.integer  "position"
    t.string   "type"
    t.string   "name"
    t.text     "value"
    t.boolean  "is_protected", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_readonly",  :default => false
  end

  create_table "clusters", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "startup_script"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "provider_account_id"
    t.integer  "servers_count",       :default => 0
    t.string   "state",               :default => "active"
  end

  add_index "clusters", ["provider_account_id"], :name => "index_clusters_on_provider_account_id"
  add_index "clusters", ["state"], :name => "index_clusters_on_state"

  create_table "clusters_users", :id => false, :force => true do |t|
    t.integer "cluster_id"
    t.integer "user_id"
  end

  add_index "clusters_users", ["cluster_id"], :name => "index_clusters_users_on_cluster_id"
  add_index "clusters_users", ["user_id"], :name => "index_clusters_users_on_user_id"

  create_table "dns_hostname_assignments", :force => true do |t|
    t.integer  "dns_hostname_id", :null => false
    t.integer  "server_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dns_hostname_assignments", ["dns_hostname_id"], :name => "unique_dns_hostname_id_idx", :unique => true
  add_index "dns_hostname_assignments", ["server_id"], :name => "index_dns_hostname_assignments_on_server_id"

  create_table "dns_hostnames", :force => true do |t|
    t.string   "name",                :limit => 64, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "provider_account_id",               :null => false
  end

  add_index "dns_hostnames", ["name"], :name => "index_dns_hostnames_on_name"
  add_index "dns_hostnames", ["provider_account_id", "name"], :name => "unique_provider_account_hostname", :unique => true

  create_table "dns_leases", :force => true do |t|
    t.integer  "dns_hostname_assignment_id",                :null => false
    t.integer  "instance_id"
    t.integer  "idx",                        :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dns_leases", ["dns_hostname_assignment_id", "idx"], :name => "index_dns_leases_on_dns_hostname_assignment_id_and_idx"
  add_index "dns_leases", ["instance_id", "dns_hostname_assignment_id"], :name => "unique_instance_hostname_assignment_idx", :unique => true

  create_table "dns_requests", :force => true do |t|
    t.enum     "request_type",               :limit => [:release, :acquire], :default => :acquire, :null => false
    t.integer  "dns_hostname_assignment_id",                                                       :null => false
    t.integer  "instance_id",                                                                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dns_requests", ["dns_hostname_assignment_id", "request_type", "instance_id"], :name => "hostname_assignment_request_instance_idx"
  add_index "dns_requests", ["instance_id"], :name => "index_dns_requests_on_instance_id"
  add_index "dns_requests", ["request_type"], :name => "index_dns_requests_on_request_type"

  create_table "events", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "provider_account_name"
    t.integer  "security_group_id"
    t.string   "security_group_name"
    t.integer  "server_id"
    t.string   "server_name"
    t.integer  "user_id"
    t.string   "user_login"
    t.string   "subject"
    t.string   "action"
    t.string   "object"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["action"], :name => "index_events_on_action"
  add_index "events", ["description"], :name => "index_events_on_description"
  add_index "events", ["object"], :name => "index_events_on_object"
  add_index "events", ["provider_account_id"], :name => "index_events_on_provider_account_id"
  add_index "events", ["provider_account_name"], :name => "index_events_on_provider_account_name"
  add_index "events", ["security_group_id"], :name => "index_events_on_security_group_id"
  add_index "events", ["security_group_name"], :name => "index_events_on_security_group_name"
  add_index "events", ["server_id"], :name => "index_events_on_server_id"
  add_index "events", ["server_name"], :name => "index_events_on_server_name"
  add_index "events", ["subject"], :name => "index_events_on_subject"
  add_index "events", ["user_id"], :name => "index_events_on_user_id"
  add_index "events", ["user_login"], :name => "index_events_on_user_login"

  create_table "firewall_rules", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "type"
    t.string   "protocol"
    t.string   "from_port"
    t.string   "to_port"
    t.string   "ip_range"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group_user_id"
    t.string   "group_name"
    t.boolean  "is_enabled",          :default => true
  end

  add_index "firewall_rules", ["name"], :name => "index_firewall_rules_on_name"
  add_index "firewall_rules", ["provider_account_id"], :name => "index_firewall_rules_on_provider_account_id"

  create_table "firewall_rules_security_groups", :id => false, :force => true do |t|
    t.integer "firewall_rule_id"
    t.integer "security_group_id"
  end

  add_index "firewall_rules_security_groups", ["firewall_rule_id"], :name => "index_firewall_rules_security_groups_on_firewall_rule_id"
  add_index "firewall_rules_security_groups", ["security_group_id"], :name => "index_firewall_rules_security_groups_on_security_group_id"

  create_table "four_oh_fours", :force => true do |t|
    t.string   "url"
    t.string   "referer"
    t.integer  "count",      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "four_oh_fours", ["url", "referer"], :name => "index_four_oh_fours_on_url_and_referer", :unique => true
  add_index "four_oh_fours", ["url"], :name => "index_four_oh_fours_on_url"

  create_table "iam_conditions", :force => true do |t|
    t.integer  "iam_statement_id"
    t.string   "type"
    t.string   "operator"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iam_conditions", ["iam_statement_id", "name"], :name => "index_iam_conditions_on_iam_statement_id_and_name"
  add_index "iam_conditions", ["iam_statement_id", "type"], :name => "index_iam_conditions_on_iam_statement_id_and_type"

  create_table "iam_policies", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.text     "description"
    t.string   "cloud_id"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iam_policies", ["provider_account_id", "cloud_id"], :name => "index_iam_policies_on_provider_account_id_and_cloud_id", :unique => true
  add_index "iam_policies", ["provider_account_id", "name"], :name => "index_iam_policies_on_provider_account_id_and_name", :unique => true

  create_table "iam_resources", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "cloud_id"
    t.string   "name"
    t.string   "type"
    t.string   "resource_path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iam_resources", ["provider_account_id", "cloud_id"], :name => "index_iam_resources_on_provider_account_id_and_cloud_id", :unique => true
  add_index "iam_resources", ["provider_account_id", "name"], :name => "index_iam_resources_on_provider_account_id_and_name", :unique => true
  add_index "iam_resources", ["provider_account_id", "resource_path"], :name => "index_iam_resources_on_provider_account_id_and_resource_path", :unique => true
  add_index "iam_resources", ["provider_account_id", "type"], :name => "index_iam_resources_on_provider_account_id_and_type"

  create_table "iam_statements", :force => true do |t|
    t.integer  "iam_policy_id"
    t.string   "sid"
    t.string   "effect"
    t.string   "action"
    t.string   "not_action"
    t.string   "resource"
    t.string   "not_resource"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iam_statements", ["iam_policy_id", "sid"], :name => "index_iam_statements_on_iam_policy_id_and_sid", :unique => true

  create_table "instance_allocation_records", :force => true do |t|
    t.integer  "stat_record_id"
    t.integer  "cluster_id"
    t.string   "cluster_name",   :default => "Default"
    t.integer  "server_id"
    t.string   "server_name",    :default => "Default"
    t.string   "instance_type"
    t.integer  "running"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
  end

  add_index "instance_allocation_records", ["stat_record_id"], :name => "index_iars_on_srids"
  add_index "instance_allocation_records", ["zone_id"], :name => "index_instance_allocation_records_on_zone_id"

  create_table "instance_kind_categories", :force => true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.text     "description"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instance_kinds", :force => true do |t|
    t.integer  "instance_kind_category_id"
    t.string   "code_name"
    t.string   "name"
    t.text     "description"
    t.boolean  "is_default"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ram_mb",                    :default => 0
    t.integer  "cpu_cores",                 :default => 0
    t.integer  "cpu_units",                 :default => 0
    t.integer  "storage_gb",                :default => 0
    t.string   "io_performance"
    t.integer  "platform_bit",              :default => 32
  end

  create_table "instance_list_readers", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "type"
    t.string   "name"
    t.string   "email"
    t.string   "s3_user_id"
    t.string   "permission"
    t.boolean  "is_owner"
    t.boolean  "is_enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "instance_list_readers", ["provider_account_id"], :name => "index_instance_list_readers_on_provider_account_id"
  add_index "instance_list_readers", ["s3_user_id"], :name => "index_instance_list_readers_on_s3_user_id"

  create_table "instance_resources", :force => true do |t|
    t.string   "type"
    t.integer  "instance_id"
    t.integer  "cloud_resource_id"
    t.string   "state"
    t.text     "state_description"
    t.boolean  "force_allocation"
    t.string   "params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mount_point"
    t.string   "mount_type"
  end

  add_index "instance_resources", ["cloud_resource_id"], :name => "index_instance_resources_on_cloud_resource_id"
  add_index "instance_resources", ["instance_id", "type"], :name => "index_instance_resources_on_instance_id_and_type"

  create_table "instance_type_categories", :force => true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.text     "description"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instances", :force => true do |t|
    t.string   "instance_id"
    t.integer  "provider_account_id"
    t.integer  "server_id"
    t.integer  "server_pool_id"
    t.string   "image_id"
    t.string   "instance_type"
    t.string   "key_name"
    t.string   "state"
    t.string   "public_dns"
    t.string   "private_dns"
    t.datetime "launch_time"
    t.string   "ramdisk_id"
    t.string   "kernel_id"
    t.string   "reason"
    t.string   "product_codes"
    t.integer  "index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "volume_name"
    t.string   "dns_name"
    t.string   "public_ip"
    t.string   "server_name"
    t.boolean  "is_locked"
    t.string   "device",                          :default => "/dev/sdh"
    t.string   "pending_volume_id"
    t.boolean  "force_volume_id_allocation"
    t.string   "pending_public_ip"
    t.boolean  "force_public_ip_allocation"
    t.boolean  "is_ready",                        :default => false
    t.integer  "cluster_id"
    t.string   "private_ip"
    t.integer  "bootstrap_attempt",               :default => 0
    t.boolean  "has_key",                         :default => false
    t.text     "status_message"
    t.integer  "user_id"
    t.boolean  "dns_active",                      :default => true
    t.integer  "zone_id"
    t.integer  "pending_launch_configuration_id"
    t.integer  "auto_scaling_group_id"
  end

  add_index "instances", ["auto_scaling_group_id"], :name => "index_instances_on_auto_scaling_group_id"
  add_index "instances", ["cluster_id"], :name => "index_instances_on_cluster_id"
  add_index "instances", ["dns_name"], :name => "index_instances_on_dns_name"
  add_index "instances", ["instance_id"], :name => "index_instances_on_instance_id"
  add_index "instances", ["key_name"], :name => "index_instances_on_key_name"
  add_index "instances", ["provider_account_id"], :name => "index_instances_on_provider_account_id"
  add_index "instances", ["public_ip"], :name => "index_instances_on_public_ip"
  add_index "instances", ["server_id"], :name => "index_instances_on_server_id"
  add_index "instances", ["server_name"], :name => "index_instances_on_server_name"
  add_index "instances", ["state"], :name => "index_instances_on_state"
  add_index "instances", ["volume_name"], :name => "index_instances_on_volume_name"
  add_index "instances", ["zone_id"], :name => "index_instances_on_zone_id"

  create_table "instances_security_groups", :id => false, :force => true do |t|
    t.integer "instance_id"
    t.integer "security_group_id"
  end

  add_index "instances_security_groups", ["instance_id"], :name => "index_instances_security_groups_on_instance_id"
  add_index "instances_security_groups", ["security_group_id"], :name => "index_instances_security_groups_on_security_group_id"

  create_table "invitations", :force => true do |t|
    t.integer  "sender_id"
    t.string   "email"
    t.string   "token"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["token"], :name => "index_invitations_on_token", :unique => true

  create_table "key_pairs", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "fingerprint"
    t.text     "private_key"
    t.text     "public_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  add_index "key_pairs", ["name"], :name => "index_key_pairs_on_name"
  add_index "key_pairs", ["provider_account_id", "name"], :name => "index_key_pairs_on_provider_account_id_and_name", :unique => true

  create_table "launch_configurations", :force => true do |t|
    t.integer  "provider_account_id"
    t.integer  "server_id"
    t.string   "name"
    t.string   "launch_configuration_name"
    t.string   "description"
    t.string   "instance_type"
    t.string   "image_id"
    t.string   "ramdisk_id"
    t.string   "kernel_id"
    t.string   "key_name"
    t.text     "user_data"
    t.datetime "created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.enum     "state",                      :limit => [:disabled, :active], :default => :disabled
    t.integer  "server_profile_revision_id"
    t.integer  "server_image_id"
  end

  add_index "launch_configurations", ["image_id"], :name => "index_launch_configurations_on_image_id"
  add_index "launch_configurations", ["launch_configuration_name"], :name => "index_launch_configurations_on_launch_configuration_name"
  add_index "launch_configurations", ["name"], :name => "index_launch_configurations_on_name"
  add_index "launch_configurations", ["provider_account_id", "launch_configuration_name"], :name => "unique_provider_account_id_launch_configuration_name", :unique => true
  add_index "launch_configurations", ["provider_account_id"], :name => "index_launch_configurations_on_provider_account_id"
  add_index "launch_configurations", ["server_id"], :name => "index_launch_configurations_on_server_id"
  add_index "launch_configurations", ["server_image_id"], :name => "index_launch_configurations_on_server_image_id"

  create_table "launch_configurations_security_groups", :id => false, :force => true do |t|
    t.integer "launch_configuration_id"
    t.integer "security_group_id"
  end

  add_index "launch_configurations_security_groups", ["launch_configuration_id"], :name => "index_configurations_groups_on_configuration_id"
  add_index "launch_configurations_security_groups", ["security_group_id"], :name => "index_configurations_groups_on_group_id"

  create_table "load_balancer_listeners", :force => true do |t|
    t.integer  "load_balancer_id"
    t.integer  "load_balancer_port"
    t.integer  "instance_port"
    t.string   "protocol"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "load_balancer_listeners", ["load_balancer_id", "load_balancer_port", "instance_port", "protocol"], :name => "index_ports_on_listener", :unique => true

  create_table "load_balancers", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "load_balancer_name"
    t.datetime "created_time"
    t.string   "d_n_s_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "load_balancers", ["provider_account_id", "load_balancer_name"], :name => "index_on_load_balancers_pa_id_and_lb_name"

  create_table "load_balancers_zones", :id => false, :force => true do |t|
    t.integer "zone_id"
    t.integer "load_balancer_id"
  end

  add_index "load_balancers_zones", ["load_balancer_id"], :name => "index_lb_id_on_azslbs"
  add_index "load_balancers_zones", ["zone_id"], :name => "index_az_id_on_azslbs"

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.text     "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "type"
    t.string   "message_id"
    t.string   "recipient"
    t.string   "sender"
    t.string   "handler"
    t.string   "state",               :default => "pending"
    t.datetime "sent_at"
    t.datetime "received_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message"
    t.text     "data"
    t.string   "status",              :default => "ok"
    t.integer  "operation_id"
    t.integer  "flags"
  end

  add_index "messages", ["operation_id"], :name => "index_messages_on_operation_id"
  add_index "messages", ["provider_account_id", "state"], :name => "index_messages_on_provider_account_id_and_state"
  add_index "messages", ["provider_account_id", "status"], :name => "index_messages_on_provider_account_id_and_status"
  add_index "messages", ["provider_account_id", "type"], :name => "index_messages_on_provider_account_id_and_type"
  add_index "messages", ["type"], :name => "index_messages_on_type"

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "operating_systems", :force => true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.string   "description"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operation_logs", :force => true do |t|
    t.integer  "operation_id"
    t.string   "step_name"
    t.boolean  "is_success"
    t.string   "result_code"
    t.text     "result_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operations", :force => true do |t|
    t.integer  "instance_id"
    t.string   "state",          :default => "proceed"
    t.string   "type"
    t.integer  "current_step",   :default => -1
    t.string   "name"
    t.text     "args"
    t.integer  "attempts",       :default => 0
    t.string   "result_code"
    t.text     "result_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "timeout_at"
    t.string   "parameter"
    t.integer  "task_id"
  end

  add_index "operations", ["state"], :name => "index_operations_on_state"

  create_table "provider_account_parameters", :force => true do |t|
    t.integer  "provider_account_id"
    t.integer  "position"
    t.string   "name"
    t.text     "value"
    t.boolean  "is_protected"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_readonly",         :default => false
  end

  add_index "provider_account_parameters", ["name"], :name => "index_provider_account_parameters_on_name"
  add_index "provider_account_parameters", ["provider_account_id", "name"], :name => "index_account_parameters_on_account_id_and_name", :unique => true

  create_table "provider_accounts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "external_id"
    t.datetime "refresh_at"
    t.datetime "refreshed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "startup_script"
    t.datetime "last_published"
    t.datetime "publish_at"
    t.integer  "publish_every",          :default => 60
    t.string   "s3_bucket"
    t.string   "s3_object"
    t.boolean  "is_publishing",          :default => true
    t.text     "static_dns_records"
    t.string   "account_id"
    t.boolean  "auto_lock_instances",    :default => false
    t.string   "default_security_group"
    t.string   "default_main_key"
    t.string   "type"
    t.integer  "provider_id"
    t.string   "messaging_uri",          :default => "",         :null => false
    t.string   "messaging_username",     :default => "",         :null => false
    t.string   "messaging_password",     :default => "",         :null => false
    t.string   "messaging_startup",      :default => "startup",  :null => false
    t.string   "messaging_shutdown",     :default => "shutdown", :null => false
    t.string   "messaging_info",         :default => "info",     :null => false
    t.string   "messaging_request",      :default => "request",  :null => false
    t.string   "messaging_control",      :default => "control",  :null => false
  end

  add_index "provider_accounts", ["id", "type"], :name => "index_provider_accounts_on_id_and_type"
  add_index "provider_accounts", ["provider_id"], :name => "index_provider_accounts_on_provider_id"

  create_table "provider_accounts_publishers", :id => false, :force => true do |t|
    t.integer "provider_account_id"
    t.integer "publisher_id"
  end

  add_index "provider_accounts_publishers", ["provider_account_id"], :name => "index_provider_accounts_publishers_on_provider_account_id"
  add_index "provider_accounts_publishers", ["publisher_id"], :name => "index_provider_accounts_publishers_on_publisher_id"

  create_table "provider_accounts_server_profiles", :id => false, :force => true do |t|
    t.integer "provider_account_id"
    t.integer "server_profile_id"
  end

  add_index "provider_accounts_server_profiles", ["provider_account_id"], :name => "index_provider_accounts_server_profiles_on_provider_account_id"
  add_index "provider_accounts_server_profiles", ["server_profile_id"], :name => "index_provider_accounts_server_profiles_on_server_profile_id"

  create_table "provider_accounts_users", :id => false, :force => true do |t|
    t.integer "provider_account_id"
    t.integer "user_id"
  end

  add_index "provider_accounts_users", ["provider_account_id"], :name => "index_provider_accounts_users_on_provider_account_id"
  add_index "provider_accounts_users", ["user_id"], :name => "index_provider_accounts_users_on_user_id"

  create_table "providers", :force => true do |t|
    t.string   "name"
    t.string   "long_name"
    t.text     "description"
    t.string   "main_documentation_url"
    t.string   "api_documentation_url"
    t.string   "endpoint_url"
    t.string   "state"
    t.string   "adapter_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "providers", ["name"], :name => "index_providers_on_name", :unique => true

  create_table "publisher_parameters", :force => true do |t|
    t.integer  "publisher_id"
    t.string   "name"
    t.string   "description"
    t.string   "value"
    t.string   "control_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publisher_parameters", ["publisher_id"], :name => "index_publisher_parameters_on_publisher_id"

  create_table "publishers", :force => true do |t|
    t.string   "type"
    t.string   "description"
    t.datetime "last_published_at"
    t.datetime "next_publish_at"
    t.boolean  "is_enabled"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "provider_account_id"
    t.text     "state_text"
  end

  create_table "regions", :force => true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.text     "description"
    t.string   "endpoint_url"
    t.string   "state"
    t.text     "meta_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name"
  end

  add_index "regions", ["name"], :name => "index_regions_on_name"
  add_index "regions", ["provider_id", "name"], :name => "index_regions_on_provider_id_and_name", :unique => true

  create_table "reserved_instances", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "reserved_instances_id"
    t.string   "instance_type"
    t.datetime "start"
    t.integer  "duration"
    t.float    "usage_price"
    t.float    "fixed_price"
    t.integer  "count"
    t.text     "description"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
  end

  add_index "reserved_instances", ["provider_account_id", "instance_type"], :name => "index_type_zone_on_reserved_instances"
  add_index "reserved_instances", ["provider_account_id", "reserved_instances_id"], :name => "index_ri_id_on_reserved_instances"
  add_index "reserved_instances", ["zone_id"], :name => "index_reserved_instances_on_zone_id"

  create_table "resource_bundles", :force => true do |t|
    t.string   "type"
    t.integer  "server_id"
    t.integer  "position"
    t.integer  "instance_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.boolean  "is_default"
  end

  add_index "resource_bundles", ["instance_id"], :name => "index_resource_bundles_on_instance_id"
  add_index "resource_bundles", ["server_id"], :name => "index_resource_bundles_on_server_id"
  add_index "resource_bundles", ["type"], :name => "index_resource_bundles_on_type"
  add_index "resource_bundles", ["zone_id"], :name => "index_resource_bundles_on_zone_id"

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "security_groups", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "owner_id"
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  add_index "security_groups", ["name"], :name => "index_security_groups_on_name"
  add_index "security_groups", ["provider_account_id", "name"], :name => "index_security_groups_on_provider_account_id_and_name", :unique => true

  create_table "security_groups_servers", :id => false, :force => true do |t|
    t.integer "security_group_id"
    t.integer "server_id"
  end

  add_index "security_groups_servers", ["security_group_id"], :name => "index_security_groups_servers_on_security_group_id"
  add_index "security_groups_servers", ["server_id"], :name => "index_security_groups_servers_on_server_id"

  create_table "security_groups_users", :id => false, :force => true do |t|
    t.integer "security_group_id"
    t.integer "user_id"
  end

  add_index "security_groups_users", ["security_group_id"], :name => "index_security_groups_users_on_security_group_id"
  add_index "security_groups_users", ["user_id"], :name => "index_security_groups_users_on_user_id"

  create_table "server_images", :force => true do |t|
    t.string   "image_id"
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "type"
    t.string   "kernel_id"
    t.string   "ramdisk_id"
    t.string   "owner_id"
    t.boolean  "is_public"
    t.string   "state"
    t.string   "location"
    t.string   "architecture"
    t.string   "server_image_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_enabled",          :default => true
  end

  add_index "server_images", ["image_id"], :name => "index_server_images_on_image_id"
  add_index "server_images", ["name"], :name => "index_server_images_on_name"
  add_index "server_images", ["provider_account_id"], :name => "index_server_images_on_provider_account_id"

  create_table "server_parameters", :force => true do |t|
    t.integer  "server_id"
    t.integer  "position"
    t.string   "name"
    t.text     "value"
    t.boolean  "is_protected"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_readonly",  :default => false
  end

  add_index "server_parameters", ["server_id"], :name => "index_server_parameters_on_server_id"

  create_table "server_profile_revision_parameters", :force => true do |t|
    t.integer  "server_profile_revision_id"
    t.integer  "position"
    t.string   "type"
    t.string   "name"
    t.text     "value"
    t.boolean  "is_protected",               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "server_profile_revision_parameters", ["server_profile_revision_id"], :name => "index_sprp_spr_id"

  create_table "server_profile_revisions", :force => true do |t|
    t.integer  "server_profile_id"
    t.integer  "revision",          :default => 0
    t.integer  "creator_id"
    t.text     "commit_message"
    t.string   "image_id"
    t.string   "ramdisk_id"
    t.string   "kernel_id"
    t.text     "startup_script"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "instance_type",     :default => "m1.small"
  end

  create_table "server_profile_user_accesses", :force => true do |t|
    t.integer  "server_profile_id"
    t.integer  "user_id"
    t.string   "role",              :default => "reader"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "server_profiles", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "provider_account_id"
  end

  add_index "server_profiles", ["provider_account_id"], :name => "index_server_profiles_on_provider_account_id"

  create_table "server_resources", :force => true do |t|
    t.string   "type"
    t.integer  "cloud_resource_id"
    t.string   "description"
    t.boolean  "force_allocation"
    t.string   "params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mount_point"
    t.integer  "resource_bundle_id"
    t.string   "mount_type"
  end

  add_index "server_resources", ["cloud_resource_id"], :name => "index_server_resources_on_cloud_resource_id"
  add_index "server_resources", ["resource_bundle_id"], :name => "index_server_resources_on_resource_bundle_id"
  add_index "server_resources", ["type"], :name => "index_server_resources_on_server_id_and_type"

  create_table "server_user_accesses", :force => true do |t|
    t.integer  "server_id"
    t.integer  "user_id"
    t.string   "server_user"
    t.integer  "schedule_id"
    t.boolean  "is_enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "status_message"
  end

  add_index "server_user_accesses", ["schedule_id"], :name => "index_server_user_accesses_on_schedule_id"
  add_index "server_user_accesses", ["server_id", "user_id", "server_user"], :name => "index_user_accesses_on_server_user_server_user", :unique => true
  add_index "server_user_accesses", ["server_user"], :name => "index_server_user_accesses_on_server_user"
  add_index "server_user_accesses", ["user_id"], :name => "index_server_user_accesses_on_user_id"

  create_table "servers", :force => true do |t|
    t.string   "name"
    t.string   "key_name"
    t.string   "public_ip"
    t.string   "volume_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "volume_name"
    t.string   "dns_name"
    t.boolean  "force_public_ip_allocation", :default => false
    t.boolean  "force_volume_id_allocation", :default => false
    t.boolean  "is_locked"
    t.string   "device",                     :default => "/dev/sdh"
    t.integer  "cluster_id"
    t.integer  "server_profile_revision_id"
    t.integer  "parent_server_id"
    t.string   "volume_class",               :default => "Volume"
    t.integer  "zone_id"
    t.integer  "instances_count",            :default => 0
  end

  add_index "servers", ["cluster_id"], :name => "index_servers_on_cluster_id"
  add_index "servers", ["cluster_id"], :name => "index_servers_on_hostname_template_and_cluster_id"
  add_index "servers", ["dns_name"], :name => "index_servers_on_dns_name"
  add_index "servers", ["key_name"], :name => "index_servers_on_key_name"
  add_index "servers", ["name"], :name => "index_servers_on_name"
  add_index "servers", ["public_ip"], :name => "index_servers_on_public_ip"
  add_index "servers", ["volume_id"], :name => "index_servers_on_volume_id"
  add_index "servers", ["volume_name"], :name => "index_servers_on_volume_name"
  add_index "servers", ["zone_id"], :name => "index_servers_on_zone_id"

  create_table "service_overrides", :force => true do |t|
    t.integer  "service_provider_id",                                  :null => false
    t.string   "target_type",         :limit => 100,                   :null => false
    t.integer  "target_id",                                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "overridable",                        :default => true
  end

  add_index "service_overrides", ["service_provider_id", "target_type", "target_id"], :name => "idx_spid_ttype_tid", :unique => true
  add_index "service_overrides", ["service_provider_id"], :name => "index_service_overrides_on_service_provider_id"
  add_index "service_overrides", ["target_id", "target_type"], :name => "index_service_overrides_on_target_id_and_target_type"

  create_table "service_providers", :force => true do |t|
    t.integer  "service_type_id",               :null => false
    t.integer  "server_id",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",            :limit => 75
    t.text     "description"
  end

  add_index "service_providers", ["server_id"], :name => "index_service_providers_on_server_id"
  add_index "service_providers", ["service_type_id", "server_id"], :name => "idx_sp_service_type_server_id", :unique => true

  create_table "service_types", :force => true do |t|
    t.string   "name",        :limit => 60, :null => false
    t.string   "fqdn",                      :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_types", ["fqdn"], :name => "index_service_types_on_fqdn", :unique => true
  add_index "service_types", ["name"], :name => "index_service_types_on_name", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "snapshots", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "snapshot_id"
    t.string   "volume_id"
    t.string   "volume_name"
    t.string   "status"
    t.datetime "start_time"
    t.string   "progress"
    t.boolean  "is_enabled",          :default => true
    t.string   "device"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_id"
    t.string   "description"
  end

  add_index "snapshots", ["description"], :name => "index_snapshots_on_description"
  add_index "snapshots", ["name"], :name => "index_snapshots_on_name"
  add_index "snapshots", ["owner_id"], :name => "index_snapshots_on_owner_id"
  add_index "snapshots", ["provider_account_id"], :name => "index_snapshots_on_provider_account_id"
  add_index "snapshots", ["snapshot_id"], :name => "index_snapshots_on_snapshot_id"
  add_index "snapshots", ["volume_id"], :name => "index_snapshots_on_volume_id"
  add_index "snapshots", ["volume_name"], :name => "index_snapshots_on_volume_name"

  create_table "stat_records", :force => true do |t|
    t.integer  "provider_account_id"
    t.datetime "taken_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stat_records", ["provider_account_id", "taken_at"], :name => "index_stat_records_on_provider_account_id_and_taken_at"

  create_table "task_parameters", :force => true do |t|
    t.integer  "task_id"
    t.string   "name"
    t.string   "description"
    t.string   "value_type"
    t.string   "regex"
    t.boolean  "is_required"
    t.string   "custom_value"
    t.string   "value_provider_type"
    t.integer  "value_provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_parameters", ["task_id"], :name => "index_task_parameters_on_task_id"
  add_index "task_parameters", ["value_provider_type", "value_provider_id"], :name => "index_task_parameters_on_vp_type_and_vp_id"

  create_table "tasks", :force => true do |t|
    t.integer  "taskable_id"
    t.string   "name"
    t.string   "description"
    t.string   "operation"
    t.datetime "active_from"
    t.datetime "active_to"
    t.boolean  "is_active"
    t.boolean  "is_scheduled"
    t.boolean  "is_repeatable"
    t.integer  "run_every_value"
    t.string   "run_every_units"
    t.datetime "run_at"
    t.integer  "run_in_value"
    t.string   "run_in_units"
    t.string   "run_cron"
    t.integer  "timeout"
    t.string   "state"
    t.text     "state_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "parent_type"
    t.integer  "parent_id"
    t.string   "taskable_type",   :default => "Server"
  end

  create_table "user_failures", :force => true do |t|
    t.string   "remote_ip"
    t.string   "http_user_agent"
    t.string   "failure_type"
    t.string   "username"
    t.integer  "count",           :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_failures", ["remote_ip"], :name => "index_user_failures_on_remote_ip"

  create_table "users", :force => true do |t|
    t.string   "user_type"
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.boolean  "enabled",                                  :default => true
    t.string   "identity_url"
    t.integer  "invitation_id"
    t.integer  "invitation_limit"
    t.text     "public_key"
    t.string   "time_zone",                                :default => "Eastern Time (US & Canada)"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name"

  create_table "volumes", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.string   "volume_id"
    t.string   "snapshot_id"
    t.datetime "create_time"
    t.integer  "size"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "instance_id"
    t.boolean  "is_enabled",          :default => true
    t.string   "device"
    t.string   "snapshot_name"
    t.integer  "zone_id"
  end

  add_index "volumes", ["instance_id"], :name => "index_volumes_on_instance_id"
  add_index "volumes", ["name"], :name => "index_volumes_on_name"
  add_index "volumes", ["provider_account_id"], :name => "index_volumes_on_provider_account_id"
  add_index "volumes", ["snapshot_id"], :name => "index_volumes_on_snapshot_id"
  add_index "volumes", ["snapshot_name"], :name => "index_volumes_on_snapshot_name"
  add_index "volumes", ["volume_id"], :name => "index_volumes_on_volume_id"
  add_index "volumes", ["zone_id"], :name => "index_volumes_on_zone_id"

  create_table "zones", :force => true do |t|
    t.integer  "provider_account_id"
    t.string   "name"
    t.enum     "state",               :limit => [:unavailable, :available], :default => :available
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "region_id"
  end

  add_index "zones", ["region_id"], :name => "index_zones_on_region_id"

end
