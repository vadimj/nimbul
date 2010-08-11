#
#
# This module makes the extending class 'searchable' (and also 'sortable' :) )
#
#
# The following two methods need to be present in the extending class:
#
# return array of valid sort fields
#
# def self.sort_fields
# 	%w(name description)
# end
#
# return array of valid search fields
#
# def self.search_fields
# 	%w(name description)
# end
#
# return array of valid filter fields
#
# def self.filter_fields
# 	%w(state owner_id)
# end
module Behaviors::Searchable
	module ClassBehaviors
		def find_all_by_parent(parent, options={})
			parent_type = parent.class.to_s.underscore
			send("find_all_by_#{ parent_type }", parent, options)
		end

		def find_all_by_user(user, options={})
			options = options_for_find_by_user(user, options)
			find(:all, options)
		end
		
		def count_all_by_user(user, options={})
			options = options_for_find_by_user(user, options)
			count(:all, options)
		end

		def search_by_parent(parent, search, page=nil, extra_joins=nil, extra_conditions=nil, sort=nil, filter=nil, include=nil)
			parent_type = parent.class.to_s.underscore
			# handle SiteUser and LdapUser subclasses
			parent_type = 'user' if parent.is_a?(User)
			send("search_by_#{ parent_type }", parent, search, page, extra_joins, extra_conditions, sort, filter, include)
		end

		def search_by_user(user, options={})
			options = options_for_find_by_user(user, options)
			search(options[:search], options[:page], options[:joins], options[:conditions], options[:order], options[:filter], options[:include])
		end

		def search(search, page, joins, conditions, order=nil, filters=nil, include=nil, group_by=nil)
			unless search.blank?
				conditions = [ '' ] if conditions.nil? or conditions.empty?
				conditions[0] = conditions[0] + " AND " unless conditions[0].blank?
				# support array of ids
				if search.is_a? Array
					conditions[0] = conditions[0] + table_name()+".id IN ("+search.join(',')+")" 
				else
					sfields = search_fields.collect{ |f| table_name()+".#{f} like ?" }
					conditions[0] = conditions[0] + "(#{sfields.join(' OR ')})"
					conditions = conditions.concat([ "%#{search}%" ]*search_fields.length)
				end
			end
			
			unless filters.nil? or !self.respond_to?('filter_fields')
				filters = filters.split(',') if filters.is_a?(String)
				if filters.is_a?(Array)
					fs = {}
					filters.each do |f|
						(n,v) = f.split(':')
						fs[n] = v
					end
					filters = fs
				end
				conditions = [ '' ] if conditions.nil? or conditions.empty?
				filters.each do |fname,fvalue|
					if !filter_fields.nil? and filter_fields.include?(fname) and !fvalue.blank?
						conditions[0] = conditions[0] + " AND " unless conditions[0].blank?
						conditions[0] = conditions[0] + table_name() + ".#{fname} = ?"
						fvalue = nil if fvalue == 'nil'
						conditions << fvalue
					end
				end
			end

			order = nil if order.blank?
			
			# make sure we always order by a valid field
			unless order.nil?
				verify_field = order.sub(table_name()+'.','').sub(/_reverse/,'').sub(/\s+DESC/,'')
				if sort_fields.include?(verify_field)
					# field is included - great
				elsif sort_fields.size > 0
					# field is not allowed - pick the first one if it's available
					order = sort_fields[0]
				else
					order = nil
				end
			end
			
			# make sure we process _reverse and include table name
			unless order.blank?
				order = order.sub(/_reverse/,' DESC')
				order = table_name()+".#{order}" unless order.include?(table_name()+".")
			end

			page = 1 if page.blank?
			paginate :page => page,
				:joins => joins,
				:conditions => conditions,
				:order => order,
				:include => include,
				:group => group_by
		end
	end # class methods
end
