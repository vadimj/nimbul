
class IamResource < BaseModel
    belongs_to :provider_account
    validates_presence_of :provider_account_id, :type, :cloud_id, :name, :resource_path
    validates_length_of :cloud_id, :maximum => 32
    validates_length_of :name, :maximum => 128
    validates_each :resource_path do |record, attr, value|
        count = record.path(value).length - 512
        record.errors.add attr, "needs to be under #{count} characters" if count > 0
    end
    validates_uniqueness_of :cloud_id, :scope => :provider_account_id
    validates_uniqueness_of :name, :scope => :provider_account_id
    validates_uniqueness_of :resource_path, :scope => :provider_account_id
    
    # return a path like arn:aws:<vendor>
    # for iam service vendor = iam
    def vendor_path
        'arn:aws:iam'
    end

    # return a path like arn:aws:<vendor>:<region> 
    # for iam service region is empty (iam is a global service)
    def region_path
        vendor_path+':'
    end

    # return a path like arn:aws:<vendor>:<region>:<namespace>
    # for iam service namespace = aws account id
    def namespace_path
        region_path+':'+self.provider_account.account_id
    end

    # returns <relative-id> - specific resource identifier
    def relative_id(rpath = nil)
        rpath ||= self.resource_path
        p = self.class.to_s.gsub(/^Iam/,'').underscore
        p += (self.resource_path[0,1] == '/') ? self.resource_path : '/'+self.resource_path
    end

    # returns fulle path like arn:aws:<vendor>:<region>:<namespace>:<relative-id>
    def path(rpath = nil)
        rid = relative_id(rpath)
        self.namespace_path+':'+rid
    end
end
