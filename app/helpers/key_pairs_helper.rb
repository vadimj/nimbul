module KeyPairsHelper
    def add_key_pair_link(name)
        link_to_function name do |page|
            page.insert_html :top, :key_pair_records, :partial => "key_pairs/key_pair", :object => @provider_account.key_pairs.build
        end
    end

	# sorting helpers
	def key_pairs_sort_link(text, param)
		sort_link(text, param, :key_pairs, nil, :list)
	end
end
