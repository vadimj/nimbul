class ServerTask < Task
    def self.find_all_by_server(server, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
        joins = []
        joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'taskable_id = ? AND taskable_type = ?', (server.is_a?(Server) ? server.id : server), 'Server' ]
        unless extra_conditions.blank?
            extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
            conditions[0] << ' AND ' + extra_conditions[0];
            conditions << extra_conditions[1..-1]
        end

        self.search(search, page, joins, conditions, sort, filter)
    end

    def run!
        begin
            taskable.instances.each do |instance|
                next if not instance.running?
                operation = get_operation
                instance.operations << operation
                # store to return to the ui
                self.new_operations = [] if self.new_operations.nil?
                self.new_operations << operation
            end
        rescue
            self.state_text = "Task failed: #{$!}"
            return false
        end
        return true
    end
end
