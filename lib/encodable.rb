module Encodable
  autoload(:ActiveRecord, 'encodable/active_record')
  autoload(:Array, 'encodable/array')
end

if defined? ActiveRecord::Base
  ActiveRecord::Base.extend Encodable::ActiveRecord::ClassMethods
  ActiveRecord::Base.send :include, Encodable::ActiveRecord::InstanceMethods
  require 'encodable/array'
end
