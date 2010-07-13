module TrackChanges
    def self.included(base)
        base.after_save :track_changes
    end

    def track_changes
        @tracked_changes = self.changes.reject{|k,v| ['created_at', 'updated_at'].include?(k.to_s)}
    end
    private :track_changes

    def tracked_changes
        @tracked_changes
    end
end

