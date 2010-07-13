# uncomment below for memcache backed models
# require 'cached_model' 
# class BaseModel < CachedModel

require 'behaviors'

class BaseModel < ActiveRecord::Base
  ##
  # As so eloquently put in the Cached Model gem:
  #
  # Override the flawed assumption ActiveRecord makes about
  # inheritance. Note: This MUST be set *before* any behaviors are defined.
  self.abstract_class = true

  # include behaviors into base class for later behavior additions
  include Behaviors

  # by default, always add searchable
  behaviors :searchable, :array_access_finder

  def to_json(options={})
    options.merge!({:methods => :status_message}) if self.respond_to?(:status_message)
    super options
  end
end
