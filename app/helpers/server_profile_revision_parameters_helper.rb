module ServerProfileRevisionParametersHelper
    def add_server_profile_revision_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :server_profile_revision_parameters, :partial => 'server_profile_revision_parameters/parameter', :object => ServerProfileRevisionParameter.new
        end
    end
end
