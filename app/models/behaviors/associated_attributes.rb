module Behaviors::AssociatedAttributes
  module ClassBehaviors
    def association_attributes *associations
      associations.compact.each do |association|
        singular_name = association.to_s.downcase.singularize
        plural_name   = singular_name.pluralize

        class_eval(<<-EOS, __FILE__, __LINE__)
          def save_#{plural_name}
            #{plural_name}.each { |i| i.should_destroy? ? i.destroy : i.save }
          end

          def #{singular_name}_attributes=(#{singular_name}_attributes)
            #{singular_name}_attributes.each do |attributes|
              if attributes[:id].blank?
                #{plural_name}.build(attributes)
              else
                #{singular_name} = #{plural_name}.detect { |c| c.id == attributes[:id].to_i }
                #{singular_name}.attributes = attributes
              end
            end
          end
        EOS
      end
    end
    alias :association_attribute :association_attributes
  end
end
