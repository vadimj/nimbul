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

  def self.inherited child
    # if we're in development mode (i.e., /not/ caching
    # classes) make sure that each model is unloadable
    # fixes a bug whereby roles/siteuser aren't reloaded.
    unless Rails.configuration.cache_classes
      child.class_eval(<<-'EOS', __FILE__, __LINE__)
        ActiveSupport::Dependencies.unloadable self
      EOS
    end
    super child
  end
  
  # include behaviors into base class for later behavior additions
  include Behaviors

  # by default, always add searchable
  behaviors :searchable, :array_access_finder

  def to_json(options={})
    options.merge!({:methods => :status_message}) if self.respond_to?(:status_message)
    super options
  end
end
