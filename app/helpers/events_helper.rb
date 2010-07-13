module EventsHelper
	# sorting helpers
	def events_sort_link(text, param)
		sort_link(text, param, :events, nil, :list)
	end
end
