attr_encodable
=

Never override `as_json` again! **attr_encodable** adds attribute black- or white-listing for ActiveRecord serialization, as well as default serialization options. This is especially useful for protecting private attributes when building a public API.

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

White-listing
===

You can whitelist or blacklist attributes for serialization using the `attr_encodable` and `attr_unencodable` class methods. Let's look at an example. For this example, we'll use the following classes:

	class User < ActiveRecord::Base
		has_many :permissions
		validates_presence_of :email, :password
		
		def foobar
			"baz"
		end
	end
	
	class Permission < ActiveRecord::Base
		belongs_to :user
		validates_presence_of :name, :user

		def hello
			"World!"
		end
	end
 
... with the following schema:

	create_table :permissions, :force => true do |t|
		t.belongs_to :user
		t.string :name
	end
	
	create_table :users, :force => true do |t|
		t.string :login, :limit => 48
		t.string :email, :limit => 128
		t.string :name, :limit => 32
		t.string :password, :limit => 60
		t.boolean :admin, :default => false
	end

Let's make a user and try encoding them:

	@user = User.create(:name => "Flip", :email => "flip@x451.com", :password => "awesomesauce", :admin => true)
 	=> #<User id: 1, login: nil, email: "flip@x451.com", name: "Flip", password: "awesomesauce", admin: true> 
	@user.to_json
 	=> {"name":"Flip","admin":true,"id":1,"password":"awesomesauce","login":null,"email":"flip@x451.com"}

Trouble is, we don't want their admin status OR their password coming through in our API. So why not protect their information a little bit?

	User.attr_encodable :id, :name, :login, :email
	@user.to_json
	 => {"name":"Flip","id":1,"login":null,"email":"flip@x451.com"}

Ah, that's so much better! Now whenever we encode a user instance we'll be showing only some default information.

`attr_unencodable` is similar, except that it bans an attribute. Following along with the example above, if we then called `attr_unencodable`, we could
restrict our user's information even more. Let's say I don't want my e-mail getting out:

	User.attr_unencodable :email
	@user.to_json
	 => {"name":"Flip","id":1,"login":null}

Alright! Now you can't see my e-mail. Sucker.

Default `:include` and `:method` options
===

`to_json` isn't just concerned with attributes. It also supports `:include`, which includes a relationship with `to_json` called on **it**, as well `:methods`, which adds the result of calling methods on the instance as well.

Let's try it out.

	User.attr_encodable :foobar
	@user.to_json
	 => {"name":"Flip","foobar":"baz","id":1,"login":null}

With includes, our example might look like this:

	class User < ActiveRecord::Base
		attr_encodable :id, :name, :login, :permissions
		has_many :permissions
	end
	
	@user.to_json
	=> {"name":"Flip","foobar":"baz","id":1,"login":null,"permissions":[]}

Neato! And of course, when `:permissions` is serialized, it will take into account any `attr_encodable` settings the Permissions class has!

Renaming Attributes
===

Sometimes you don't want an attribute to come out in JSON named what it's named in the database. There are two options you can pursue here.

Prefix it!
====

**attr_encodable** supports prefixing of attribute names. Just pass an options hash onto the end of the method with a :prefix key and you're good to go. Example:

	class User < ActiveRecord::Base
		attr_encodable :ed, :prefix => :i_will_hunt
	end

	@user.to_json
	=> {"i_will_hunt_ed":true}

Rename it completely!
====

If you don't want to prefix, just rename the whole damn thing:

	class User < ActiveRecord::Base
		attr_encodable :admin => :superuser
	end
	
	@user.to_json
	#=> {"superuser":true}

Renaming and prefixing work for any `:include` and `:methods` arguments you pass in as well!

Okay, that's all. Thanks for stopping by.

Copyright &copy; 2011 Flip Sasser

