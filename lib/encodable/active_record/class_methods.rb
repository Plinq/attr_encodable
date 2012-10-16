module Encodable
  module ActiveRecord
    module ClassMethods
      def attr_encodable(*attributes)
        options = extract_encodable_options!(attributes)

        unless @encodable_whitelist_started
          # Since we're white-listing, make sure we black-list every attribute to begin with
          unencodable_attributes(options[:as]).push *column_names.map(&:to_sym)
          @encodable_whitelist_started = true
        end

        attributes.each do |attribute|
          if attribute.is_a?(Hash)
            attribute.each do |method, value|
              add_encodable_attribute(method, value, options)
            end
          else
            add_encodable_attribute(attribute, attribute, options)
          end
        end
      end

      def add_encodable_attribute(method, value, options = {})
        value = "#{options[:prefix]}_#{value}" if options[:prefix]
        method = method.to_sym
        value = value.to_sym
        renamed_encoded_attributes(options[:as]).merge!({method => value}) if method != value
        # Un-black-list any attribute we white-listed
        unencodable_attributes(options[:as]).delete method
        default_attributes(options[:as]).push method
      end

      def attr_unencodable(*attributes)
        options = extract_encodable_options!(attributes)
        unencodable_attributes(options[:as]).push *attributes.map(&:to_sym)
      end

      def default_attributes(name = nil)
        @default_attributes ||= merge_encodable_superclass_options(:default_attributes, [])
        if name
          @default_attributes[name] ||= []
        else
          @default_attributes
        end
      end

      def encodable_sets
        @encodable_sets
      end

      def renamed_encoded_attributes(name = nil)
        @renamed_encoded_attributes ||= merge_encodable_superclass_options(:renamed_encoded_attributes, {})
        if name
          @renamed_encoded_attributes[name] ||= {}
        else
          @renamed_encoded_attributes
        end
      end

      def unencodable_attributes(name = nil)
        @unencodable_attributes ||= merge_encodable_superclass_options(:unencodable_attributes, [])
        if name
          @unencodable_attributes[name] ||= []
        else
          @unencodable_attributes
        end
      end

      private
      def extract_encodable_options!(attributes)
        begin
          attributes.last.assert_valid_keys(:prefix, :as)
          options = attributes.extract_options!
        rescue ArgumentError
        end if attributes.last.is_a?(Hash)

        options ||= {}
        options[:as] ||= :default
        options
      end

      def merge_encodable_superclass_options(method, default)
        value = {}
        superk = superclass
        while superk.respond_to?(method)
          supervalue = superk.send(method)
          case default
          when Array
            supervalue.each {|name, default| (value[name] ||= []).push *default }
          when Hash
            supervalue.each {|name, default| (value[name] ||= {}).merge! default }
          end
          superk = superk.superclass
        end
        value
      end
    end
  end
end
