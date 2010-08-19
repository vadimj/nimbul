require 'AWS/S3'
require 'pp'

class S3Adapter
    def self.get_s3(account)
        return if account.nil?
        return if account.aws_access_key.blank? or account.aws_secret_key.blank?
        keys = [ account.aws_access_key, account.aws_secret_key ]
        AWS::S3.new(*keys)
    end

    def self.get_owner_id(account)
        s3 = get_s3(account)
        s3.get_owner_id
    end

    def self.create_bucket(account, bucket)
        s3 = get_s3(account)
        s3.create_bucket(bucket) unless bucket_exists?(account, bucket)
    end

    def self.put_object(account, bucket, key, content, policy = 'private')
        s3 = get_s3(account)
        create_bucket(account, bucket) 
        # canned policy may be: 'private', 'public-read', 'public-read-write', 'authenticated-read'
        opts = {
                :data => content,
                :policy => policy,
        }
        obj = s3.create_object(bucket, key, opts)
    end

    def self.grant_read(account, bucket, key='', readers=[])
        s3 = get_s3(account)
        owner_id = s3.get_owner_id
        grants = [ owner_id => 'FULL_CONTROL' ]

        # pull the owner out to avoid overwriting full control rule
        rs = readers.collect{|r| r unless r.s3_user_id == owner_id }.compact
        rs.each do |r|
            grants << { r.s3_user_id => 'READ' }
        end

        s3.set_acl(owner_id, bucket, key, grants)
    end

    def self.get_acl(account, bucket, key='')
        s3 = get_s3(account)
        s3.get_acl(bucket, key)
    end
    
    def self.list_buckets(account)
      get_s3(account).list_buckets
    end
    
    def self.bucket_exists?(account, bucket)
      list_buckets(account)[:buckets].any? { |b| b[:name] == bucket } rescue false
    end
end
