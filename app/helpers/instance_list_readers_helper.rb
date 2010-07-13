module InstanceListReadersHelper
    def add_instance_list_reader_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :instance_list_readers, :partial => 'instance_list_reader', :object => InstanceListReader.new
        end
    end
end
