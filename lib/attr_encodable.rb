require 'active_record'

module Encodable
  module ClassMethods
    def attr_encodable(*attributes)
      unless @encodable_whitelist_started
        unencodable_attributes.push *column_names.map(&:to_sym)
        @encodable_whitelist_started = true
      end
      attributes.map!(&:to_sym)
      unencodable_attributes.delete_if {|attribute| attributes.include? attribute }
    end

    def attr_unencodable(*attributes)
      unencodable_attributes.push(*attributes.map(&:to_sym))
    end

    def unencodable_attributes
      @unencodable_attributes ||= []
    end
  end

  module InstanceMethods
    def serializable_hash(options = {})
      options ||= {}
      unless self.class.unencodable_attributes.empty?
        original_except = if options[:except]
          options[:except] = Array(options[:except]).map(&:to_sym)
        else
          options[:except] = []
        end
        options[:except].push *self.class.unencodable_attributes
        case options[:include]
        when Array, Symbol
          includes = Array(options[:include])
          # This is a little bit confusing. ActiveRecord's default behavior is to apply the :except arguments you pass
          # in to any :include options UNLESS it's overridden on the :include option. In the event that we have some
          # *default* excepts that come from Encodable, we want to ignore those and pass only whatever the original
          # :except options from the user were on down to the :include guys.
          options[:include] = Hash[*includes.map{|association| [association, {:except => original_except - self.class.unencodable_attributes, :method => nil, :methods => []}]}.flatten]
        end
      end
      super(options)
    end
  end
end

if defined? ActiveRecord::Base
  ActiveRecord::Base.extend Encodable::ClassMethods
  ActiveRecord::Base.send(:include, Encodable::InstanceMethods)
end
