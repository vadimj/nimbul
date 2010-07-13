module MessagesHelper
	def messages_sort_link(text, param)
		sort_link(text, param, :messages, nil, :list)
	end
end
