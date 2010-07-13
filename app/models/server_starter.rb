class ServerStarter
    attr_accessor :status, :status_message

    def start_server(server, options={})
	self.status = "Error_NotImplemented"
	self.status_message = "start_server method is not implemented for this Server Starter"
	return false
    end

    def class_type=(value)
	self[:type] = value
    end

    def class_type
	return self[:type]
    end

    # Factory to create instances of subclasses
    def self.factory(type, *params)
        class_name = type.nil? ? 'ServerStarter' : type

        # make sure the class is included first, and don't fail on error loading library
        require File.join(File.dirname(__FILE__), class_name.gsub(/::/, '/').downcase) rescue false

        _class = class_name.constantize rescue nil
        if not _class.nil? and _class.name == class_name
            return _class.new(*params)
        end

        # fallback to ServerStarter base
        return ServerStarter.new(params)
    end

end
