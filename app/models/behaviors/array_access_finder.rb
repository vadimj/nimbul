module Behaviors::ArrayAccessFinder
  module ClassBehaviors
    def [](*keys)
      if keys.count > 1
        if keys.all? { |k| k.kind_of? Integer }
          self.find(*keys)
          
        elsif keys.all? { |k| k.kind_of? String }
          if content_columns.any? { |c| c.name == 'name' }
            self.find_all_by_name keys
            
          elsif respond_to? :search_fields
            self.search_fields.inject([]) do |results,field|
              results |= [self.__send__("find_all_by_#{field.to_s}".to_sym, keys)]
              results
            end.flatten
            
          else
            raise "Unable to find String content - missing search_fields() method and object schema has no 'name' column"
          end
          
        else
          self.find(*keys)
        end
        
      else
        case (lookup = keys.first)
          
          when Integer
            self.find_by_id lookup
            
          when Hash
            
            conditions = lookup.inject({}) do |hash,(key,value)|
              if self.columns.any? { |c| c.name == key.to_s }
                [value].flatten.each do |v|
                  op_type = v.to_s['!'] || '='
                  (hash[key] ||= {})[op_type] ||= []
                  hash[key][op_type] |= [v.to_s[/^!{0,1}(.*)/,1]].flatten
                end
              end
              hash
            end
  
            conditions = conditions.inject([]) do |c,(field,ops)|
              args = []
              search = ops.inject([]) do |list,(op,data)|
                args |= [data].flatten
                list |= if data.count > 1
                  [ "#{field} #{op == '!' ? 'NOT ' : ''}IN (#{('? '*data.size).strip.split.join(',')})"]
                else
                  if data.first.include? '%'
                    [ op == '!' ? "#{field} NOT LIKE ?" : "#{field} LIKE ?" ]
                  elsif data.first.downcase == 'null'
                    args.pop # remove the arg we added for null
                    [ "#{field} IS #{op == '!' ? 'NOT' : ''} NULL"]
                  else
                    [ "#{field} #{op == '!' ? '!=' : '='} ?"]
                  end
                end
              end.join(' OR ')
              c |= [ ["(#{search})", args.dup ] ]; c
            end
            find(:all, :conditions => [ conditions.collect{|c|c[0]}.join(' AND '), *conditions.collect{|c|c[1]}.flatten ])
            
          when String
            if content_columns.any? { |c| c.name == 'name' }
              result = self.find_all_by_name(lookup)
              return result.first unless result.size > 1
              result
            elsif respond_to? :search_fields
              self.search_fields.inject([]) do |results,field|
                results |= [self.__send__("find_all_by_#{field.to_s}".to_sym, lookup)]
                results
              end.flatten
            else
              raise "Unable to find String content - missing search_fields() method and object schema has no 'name' column"
            end
          else
            self.find lookup
        end            
      end
    end
  end
end
