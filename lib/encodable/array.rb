Array.class_eval do
  def as_json_with_encodable(name = nil, options = nil)
    case name
    when Hash, NilClass
      options = name
    when String, Symbol
      (options ||= {}).merge! :as => name
    end
    as_json_without_encodable options
  end
  alias_method_chain :as_json, :encodable
end
