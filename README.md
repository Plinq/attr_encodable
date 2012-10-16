# attr_encodable

Never override `as_json` again! **attr_encodable** adds attribute black- or white-listing for ActiveRecord serialization, as well as default serialization options. This is especially useful for protecting private attributes when building a public API.

## Install

Bundler:

	gem 'attr_encodable'

Rubygems:

	gem install attr_encodable


## Usage

### White-listing


You can whitelist or blacklist attributes for serialization using the `attr_encodable` and `attr_unencodable` class methods. Let's look at an example. For this example, we'll use the following classes:

```ruby
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
```
 
... with the following schema:

```ruby
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
```

Let's make a user and try encoding them:

```ruby
@user = User.create(:name => "Flip", :email => "flip@x451.com", :password => "awesomesauce", :admin => true)
#=> #<User id: 1, login: nil, email: "flip@x451.com", name: "Flip", password: "awesomesauce", admin: true> 
@user.to_json
#=> {"name":"Flip","admin":true,"id":1,"password":"awesomesauce","login":null,"email":"flip@x451.com"}
```
Trouble is, we don't want their admin status OR their password coming through in our API. So why not protect their information a little bit?

```ruby
User.attr_encodable :id, :name, :login, :email
@user.to_json
#=> {"name":"Flip","id":1,"login":null,"email":"flip@x451.com"}
```

Ah, that's so much better! Now whenever we encode a user instance we'll be showing only some default information.

`attr_unencodable` is similar, except that it bans an attribute. Following along with the example above, if we then called `attr_unencodable`, we could
restrict our user's information even more. Let's say I don't want my e-mail getting out:

```ruby
User.attr_unencodable :email
@user.to_json
#=> {"name":"Flip","id":1,"login":null}
```

Alright! Now you can't see my e-mail. Sucker.

### Default `:include` and `:method` options

`to_json` isn't just concerned with attributes. It also supports `:include`, which includes a relationship with `to_json` called on **it**, as well as `:methods`, which adds the result of calling one or more methods on the instance. `attr_encodable` supports both without specifying what you want to call; just include them in your list:

```ruby
User.attr_encodable :foobar
@user.to_json
#=> {"name":"Flip","foobar":"baz","id":1,"login":null}
```

With includes, our example might look like this:

```ruby
class User < ActiveRecord::Base
  attr_encodable :id, :name, :login, :permissions
  has_many :permissions
end
	
@user.to_json
#=> {"name":"Flip","foobar":"baz","id":1,"login":null,"permissions":[]}
```

Neato! And of course, when `:permissions` is serialized, it will take into account any `attr_encodable` settings the `Permission` class has!

### Renaming Attributes

Sometimes you don't want an attribute to come out in JSON named what it's named in the database. There are two options you can pursue here.

#### Prefix it!

**attr_encodable** supports prefixing of attribute names. Just pass an options hash onto the end of the method with a :prefix key and you're good to go. Example:

```ruby
class User < ActiveRecord::Base
  attr_encodable :ed, :prefix => :i_will_hunt
end

@user.to_json
=> {"i_will_hunt_ed":true}
```

#### Rename it completely!

If you don't want to prefix, just rename the whole damn thing:

```ruby
class User < ActiveRecord::Base
  attr_encodable :admin => :superuser
end

@user.to_json
#=> {"superuser":true}
```

Renaming and prefixing work for any `:include` and `:methods` arguments you pass in as well!

### NEW! `attr_encodable` groups

Soemtimes you may want to supply more information or less information, depending on the context. For example, if your API supports listing multiple records and viewing individual records, you may want to list multiple records with just enough information to get them to a URL where they can visit the individual record in detail. In that case, you can create a group using an `:as` option:

```ruby
User.attr_encodable :login, :name, :email
User.attr_encodable :login, :as => :listing
```

This will create two groups: the default group, which is how your User will normally be serialized when you call `as_json` or `to_json` on it. Then, the `:listing` group, which can be used like so:

```ruby
@user.as_json #=> {"login": "flipsasser", "email": "support@getplinq.com", "name": "Flip Sasser"}
@user.as_json(:listing) #=> {"login": "flipsasser"}
```

This comes in super handy when you want a quick way to limit or expand data in certain situations.

To flip the example around, imagine you wanted to default to a very limited set of information, but expand it in a certain situation:

```ruby
User.attr_encodable :login
User.attr_encodable :login, :admin, :email, :password, :as => :admin_api
```

Now you can call `@user.to_json(:admin_api)` somewhere, which will include a full users' details, but any other `as_json` call will keep that information private.

#### Scopes

The use of `:as` also creates a scope on the class which is a SELECT limited only to those columns the class knows about. This enables higher-performance API calls out-of-the-box.

Using the first example from above, calling `User.listing` would result in a `SELECT login FROM users` instead of the normal `SELECT * FROM users`. Since
you're only going to be encoding the information from attr_encodable anyway, there's no sense in selecting anything else!

Okay, that's all. Thanks for stopping by.

Copyright &copy; 2011 Flip Sasser

