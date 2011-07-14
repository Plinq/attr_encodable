require 'active_record'

module Encodable
  module ClassMethods
    def attr_encodable(*attributes)
      attributes.each do |attribute|
        if attribute.is_a?(Hash)
          method, value = attribute.keys.first.to_sym, attribute.values.first.to_sym
        else
          method, value = attribute.to_sym, attribute.to_sym
        end
        if column_names.include? method.to_s
          unless @encodable_whitelist_started
            # Since we're white-listing, make sure we black-list every attribute to begin with
            unencodable_attributes.push *column_names.map(&:to_sym)
            @encodable_whitelist_started = true
          end
          # Un-black-list any attribute we white-listed
          unencodable_attributes.delete method
          default_encodable_attributes.merge!({method => value}) if attribute.is_a?(Hash)
        elsif association = reflect_on_association(method)
          default_encodable_includes.merge!({method => value})
        elsif instance_methods.map(&:to_s).include? method.to_s
          default_encodable_methods.merge!({method => value})
        else
          raise "not sure what to do with #{method}"
        end
      end
    end

    def attr_unencodable(*attributes)
      unencodable_attributes.push *attributes.map(&:to_sym)
    end

    def default_encodable_attributes
      @default_encodable_attributes ||= {}
    end

    def default_encodable_includes
      @default_encodable_includes ||= {}
    end

    def default_encodable_methods
      @default_encodable_methods ||= {}
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
      unless self.class.default_encodable_includes.empty?
        case options[:include]
        when Hash
          self.class.default_encodable_includes.each {|association, display_as| options[:include][association] ||= {} }
        else
          (options[:include] ||= []).push *self.class.default_encodable_includes.keys
        end
      end
      unless self.class.default_encodable_methods.empty?
        # case options[:methods]
        # when Hash
        #   options[:methods] = self.class.default_encodable_methods.merge(options[:include])
        # else
          (options[:methods] ||= []).push *self.class.default_encodable_methods.keys
        # end
      end
      as_json = super(options)
      as_json.each do |key, value|
        if new_key = self.class.default_encodable_attributes[key.to_sym] || self.class.default_encodable_includes[key.to_sym] || self.class.default_encodable_includes[key.to_sym]
          as_json.delete(key)
          as_json[new_key.to_s] = value
        end
      end
      as_json
    end
  end
end

if defined? ActiveRecord::Base
  ActiveRecord::Base.extend Encodable::ClassMethods
  ActiveRecord::Base.send(:include, Encodable::InstanceMethods)
end
