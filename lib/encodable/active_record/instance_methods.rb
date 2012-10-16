module Encodable
  module ActiveRecord
    module InstanceMethods
      def as_json(name = nil, options = nil)
        case name
        when Hash, NilClass
          options = name
        when String, Symbol
          (options ||= {}).merge! :as => name
        end
        super options
      end

      def serializable_hash(options = {})
        options ||= {}
        options[:as] ||= :default

        original_except = if options[:except]
          options[:except] = Array(options[:except]).map(&:to_sym)
        else
          options[:except] = []
        end

        # Convert :only to :except
        if options && options[:only]
          options[:except].push *self.class.default_attributes(options[:as]) - Array(options.delete(:only).map(&:to_sym))
        end

        # This is a little bit confusing. ActiveRecord's default behavior is to apply the :except arguments you pass
        # in to any :include options UNLESS it's overridden on the :include option. In the event that we have some
        # *default* excepts that come from Encodable, we want to ignore those and pass only whatever the original
        # :except options from the user were on down to the :include guys.
        inherited_except = original_except - self.class.default_attributes(options[:as])
        case options[:include]
        when Array, Symbol
          # Convert includes arrays or singleton symbols into a hash with our original_except scope
          includes = Array(options[:include])
          options[:include] = Hash[*includes.map{|association| [association, {:except => inherited_except}]}.flatten]
        else
          options[:include] ||= {}
        end
        # Exclude the black-list
        options[:except].push *self.class.unencodable_attributes(options[:as])
        # Include any default :include or :methods arguments that were passed in earlier
        self.class.default_attributes(options[:as]).each do |attribute, as|
          unless options[:except].include?(attribute)
            if association = self.class.reflect_on_association(attribute)
              options[:include][attribute] = {:except => inherited_except}
            elsif respond_to?(attribute) && !self.class.column_names.include?(attribute.to_s)
              options[:methods] ||= Array(options[:methods]).compact
              options[:methods].push attribute
            end
          end
        end
        as_json = super(options)
        self.class.renamed_encoded_attributes(options[:as]).each do |attribute, as|
          if as_json.has_key?(attribute) || as_json.has_key?(attribute.to_s)
            as_json[as.to_s] = as_json.delete(attribute) || as_json.delete(attribute.to_s)
          end
        end
        as_json
      end
    end
  end
end
