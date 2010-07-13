module OperationsHelper
    def add_operation_link(name)
        link_to_function name do |page|
            page.insert_html :top, :operation_records, :partial => "operations/operation", :object => Operation.new
        end
    end

	# sorting helpers
	def operations_sort_link(text, param)
		sort_link(text, param, :operations, nil, :list)
	end
end
