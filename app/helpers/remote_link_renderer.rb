class RemoteLinkRenderer < WillPaginate::LinkRenderer
	def prepare(collection, options, template)
		@remote = options.delete(:remote) || {}
		super
	end

	protected
	def page_link(page, text, attributes = {})
		options = {
			:url => url_for(page),
			:method => :get,
		}.merge(@remote)
		html_options = {
			:href => url_for(page),
			:method => :get,
		}
		@template.link_to_remote text, options, html_options
	end

end
