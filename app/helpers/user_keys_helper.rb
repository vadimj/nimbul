module UserKeysHelper
    def add_user_user_key_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :user_user_keys, :partial => 'user/user_keys/user_key', :object => UserKey.new
        end
    end
end
