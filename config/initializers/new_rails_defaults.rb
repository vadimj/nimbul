# These settings change the behavior of Rails 2 apps and will be defaults
# for Rails 3. You can remove this initializer when Rails 3 is released.

# Include Active Record class name as root for JSON serialized output.
ActiveRecord::Base.include_root_in_json = true

# Store the full class name (including module namespace) in STI type column.
ActiveRecord::Base.store_full_sti_class = true

# Use ISO 8601 format for JSON serialized times and dates.
ActiveSupport.use_standard_json_time_format = true

# Don't escape HTML entities in JSON, leave that for the #json_escape helper.
# if you're including raw json in an HTML page.
ActiveSupport.escape_html_entities_in_json = false


# for more info, see: http://ozmm.org/posts/try.html 
#
# dirty little helper method that protects us from nils
# 
# used like so: 
# 
#   Person.find_by_email(nonexistant_email).try(:name)
#
#   This will return nil if find didn't find the record or 
#   the name if it found the record

class Object
	def try(method, *args)
		send(method, *args) rescue nil if respond_to? method
	end

	if self.respond_to? :empty?
  	alias :original_empty? :empty?
	end

  def empty?
    unless respond_to? :original_empty?
      nil?
    else
      original_empty?
    end
  end
end

class ActiveRecord::Base
  # Overriding internal ActiveRecord::Base behavior here.
  #
  # This forces subclasses to be required when loading them, which fixes
  # a bug in ruby's constant searching routines where it always searches
  # the toplevel scope. For example, if you have the following
  #
  # module Mysql
  # end
  #
  # class Operations::Snapshot::Mysql
  # end
  #
  # when the subclass operation gets loaded, depending on load order,
  # it could end up using the top level mysql class instead of the
  # actual mysql operation subclass.
  #
  # see: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/80829
  #
  # Note: this bug is particularly noticable in development mode but,
  # theoretically possible in production mode (i.e., class caching on)
  #
  class << self
    def compute_type(type_name)
      modularized_name = type_name_with_module(type_name)
      silence_warnings do
        begin
          _get_sti_constant modularized_name
        rescue NameError
          _get_sti_constant type_name
        end
      end   
    end
    
    def _get_sti_constant type_name
      type_name.split('::').inject(Object) do |object,const|
        unless object.constants.include? const.camelize
          klass = "#{object == Object ? '' : "#{object.to_s}::"}#{const}".underscore
          load "#{klass}.rb" rescue nil
        end
        object = object.const_get(const); object
      end
    end
  end
end

