module ServerParametersHelper
    def add_server_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :server_parameters, :partial => 'server_parameters/server_parameter', :object => ServerParameter.new
        end
    end
end
