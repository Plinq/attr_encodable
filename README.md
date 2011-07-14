attr_encodable
=

**attr_encodable** adds attribute black- or white-listing for ActiveRecord serialization. It enables you to set up defaults for what is included or excluded when you serialize an ActiveRecord object. This is especially useful for protecting private attributes when building a public API.

Install
==

Install using Rubygems:

	gem install attr_encodable

Install using Bundler:

  gem 'attr_encodable'

Install in Rails 2.x (in your environment.rb file)

  config.gem 'attr_encodable'

Usage
==

You can whitelist or blacklist attributes for serialization using the `attr_encodable` and `attr_unencodable` class methods. For example:

class User < ActiveRecord::Base
  attr_encodable :id, :name, :email
end

Now, when you call `to_json` on an instance of User, the only attributes that will be added to the JSON hash are :id, :name, and :email.

`attr_unencodable` is similar, except that it bans an attribute.

That's it. It's really, really, unbelievably simple. Enjoy!
