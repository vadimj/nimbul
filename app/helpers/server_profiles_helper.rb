module ServerProfilesHelper
    def add_server_profile_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :server_profile_parameters, :partial => 'server_profiles/parameter', :locals => { :server_profile_revision_parameter => ServerProfileRevisionParameter.new }
        end
    end
end
