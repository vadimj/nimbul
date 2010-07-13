module ClusterParametersHelper
    def add_cluster_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :cluster_parameters, :partial => 'cluster_parameters/cluster_parameter', :object => ClusterParameter.new
        end
    end
end
