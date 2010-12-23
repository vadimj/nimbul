module ProvidersHelper
  def expand_provider_objects_link(provider, objects)
    poid = provider_objects_id(provider, objects)
    elid = expand_link_id(provider, objects)
    clid = compress_link_id(provider, objects)
    
    link_text = image_tag(
      'expand.png', :class => 'small-icon', :alt => 'expand'
    )
    
    begin
      url = polymorphic_url([provider, objects])
      options = {
        :url => url,
        :method => :get,
        :update => poid,
        :success => "$('#{elid}').hide();$('#{clid}').show();$('#{poid}').show();$('loading').hide();",
      }
      html_options = {
        :href => url,
        :method => :get,
        :title => "Show #{objects.to_s} for Provider '#{provider.name}'",
      }
      link = link_to_remote link_text, options, html_options
    rescue
      link = link_to_function(
        link_text,
        "$('#{elid}').hide();$('#{clid}').show();$('#{poid}').show();"
      )
    end

    content_tag(:span, link, :id => elid)
  end

  def compress_provider_objects_link(provider, objects)
    poid = provider_objects_id(provider, objects)
    elid = expand_link_id(provider, objects)
    clid = compress_link_id(provider, objects)
    
    link_text = image_tag(
      'contract.png', :class => 'small-icon', :alt => 'contract'
    )
    
    link = link_to_function(
      link_text,
      "$('#{clid}').hide();$('#{elid}').show();$('#{poid}').hide();"
    )
    content_tag(:span, link, :id => clid, :style => 'display:none;')
  end

  def provider_objects_id(provider, objects)
    "provider-#{provider.id}-#{objects.to_s}"
  end

  def expand_link_id(provider, objects)
    "provider-#{provider.id}-#{objects.to_s}-expand_link"
  end
  
  def compress_link_id(provider, objects)
    "provider-#{provider.id}-#{objects.to_s}-compress_link"
  end
end
