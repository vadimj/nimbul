module ProviderAccountParametersHelper
    def add_provider_account_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :provider_account_parameters, :partial => 'provider_account_parameters/provider_account_parameter', :object => ProviderAccountParameter.new
        end
    end
end
