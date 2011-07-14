require "lib/attr_encodable"

describe Encodable do
  it "should automatically extend ActiveRecord::Base" do
    ActiveRecord::Base.should respond_to(:attr_encodable)
    ActiveRecord::Base.should respond_to(:attr_unencodable)
  end

  before :each do
    ActiveRecord::Base.include_root_in_json = false
    ActiveRecord::Base.establish_connection({:adapter => 'sqlite3', :database => ':memory:', :pool => 5, :timeout => 5000})
    class ::Permission < ActiveRecord::Base; belongs_to :user; def hello; "World!"; end; end
    class ::User < ActiveRecord::Base; has_many :permissions; def foobar; "baz"; end; end
    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :permissions, :force => true do |t|
          t.belongs_to :user
          t.string :name
        end
        create_table :users, :force => true do |t|
          t.string   "login",              :limit => 48
          t.string   "email",              :limit => 128
          t.string   "first_name",         :limit => 32
          t.string   "last_name",          :limit => 32
          t.string   "encrypted_password", :limit => 60
          t.boolean  "developer",                         :default => false
          t.boolean  "admin",                          :default => false
          t.boolean  "password_set",                      :default => true
          t.boolean  "verified",                          :default => false
          t.datetime "created_at"
          t.datetime "updated_at"
          t.integer  "notifications"
        end
      end
    end
    @user = User.create({
      :login => "flipsasser",
      :first_name => "flip",
      :last_name => "sasser",
      :email => "flip@foobar.com",
      :encrypted_password => ActiveSupport::SecureRandom.hex(30),
      :developer => true,
      :admin => true,
      :password_set => true,
      :verified => true,
      :notifications => 7
    })
    @user.permissions.create(:name => "create_blog_posts")
    @user.permissions.create(:name => "edit_blog_posts")
    # Reset the options for each test
    [Permission, User].each do |klass|

      klass.class_eval do
        @default_attributes = nil
        @encodable_whitelist_started = nil
        @renamed_encoded_attributes = nil
        @unencodable_attributes = nil
      end
    end
  end

  it "should favor whitelisting to blacklisting" do
    User.unencodable_attributes.should == []
    User.attr_unencodable 'foo', 'bar', 'baz'
    User.unencodable_attributes.should == [:foo, :bar, :baz]
    User.attr_encodable :id, :first_name
    User.unencodable_attributes.map(&:to_s).should == ['foo', 'bar', 'baz'] + User.column_names - ['id', 'first_name']
  end

  describe "at the parent model level" do
    it "should not mess with to_json unless when attr_encodable and attr_unencodable are not set" do
      @user.as_json == @user.attributes
    end

    it "should not mess with :include options" do
      @user.as_json(:include => :permissions) == @user.attributes.merge(:permissions => @user.permissions.as_json)
    end

    it "should not mess with :methods options" do
      @user.as_json(:methods => :foobar) == @user.attributes.merge(:foobar => "baz")
    end

    it "should allow me to whitelist attributes" do
      User.attr_encodable :login, :first_name, :last_name
      @user.as_json.should == @user.attributes.slice('login', 'first_name', 'last_name')
    end

    it "should allow me to blacklist attributes" do
      User.attr_unencodable :login, :first_name, :last_name
      @user.as_json.should == @user.attributes.except('login', 'first_name', 'last_name')
    end

    # Of note is the INSANITY of ActiveRecord in that it applies :only / :except to :include as well. Which is
    # obviously insane. Similarly, it doesn't allow :methods to come along when :only is specified. Good god, what
    # a shame.
    it "should allow me to whitelist attributes without messing with :include" do
      User.attr_encodable :login, :first_name, :last_name
      @user.as_json(:include => :permissions).should == @user.attributes.slice('login', 'first_name', 'last_name').merge(:permissions => @user.permissions.as_json)
    end

    it "should allow me to blacklist attributes without messing with :include and :methods" do
      User.attr_unencodable :login, :first_name, :last_name
      @user.as_json(:include => :permissions, :methods => :foobar).should == @user.attributes.except('login', 'first_name', 'last_name').merge(:permissions => @user.permissions.as_json, :foobar => "baz")
    end

    it "should not screw with :include if it's a hash" do
      User.attr_unencodable :login, :first_name, :last_name
      @user.as_json(:include => {:permissions => {:methods => :hello, :except => :id}}, :methods => :foobar).should == @user.attributes.except('login', 'first_name', 'last_name').merge(:permissions => @user.permissions.as_json(:methods => :hello, :except => :id), :foobar => "baz")
    end
  end

  describe "at the child model level when the paren model has attr_encodable set" do
    before :each do
      User.attr_encodable :login, :first_name, :last_name
    end

    it "should not mess with to_json unless when attr_encodable and attr_unencodable are not set on the child, but are on the parent" do
      @user.permissions.as_json == @user.permissions.map(&:attributes)
    end

    it "should not mess with :include options" do
      # This is testing that the implicit ban on the :id attribute from User.attr_encodable is not
      # applying to serialization of permissions
      @user.as_json(:include => :permissions)[:permissions].first['id'].should_not be_nil
    end

    it "should inherit any attr_encodable options from the child model" do
      User.attr_encodable :id
      Permission.attr_encodable :name
      as_json = @user.as_json(:include => :permissions)
      as_json[:permissions].first['id'].should be_nil
      as_json['id'].should_not be_nil
    end
    
    # it "should allow me to whitelist attributes" do
    #   User.attr_encodable :login, :first_name, :last_name
    #   @user.as_json.should == @user.attributes.slice('login', 'first_name', 'last_name')
    # end
    # 
    # it "should allow me to blacklist attributes" do
    #   User.attr_unencodable :login, :first_name, :last_name
    #   @user.as_json.should == @user.attributes.except('login', 'first_name', 'last_name')
    # end
  end

  it "should let me specify automatic includes as well as attributes" do
    User.attr_encodable :login, :first_name, :id, :permissions
    @user.as_json.should == @user.attributes.slice('login', 'first_name', 'id').merge(:permissions => @user.permissions.as_json)
  end

  it "should let me specify methods as well as attributes" do
    User.attr_encodable :login, :first_name, :id, :foobar
    @user.as_json.should == @user.attributes.slice('login', 'first_name', 'id').merge(:foobar => "baz")
  end

  describe "reassigning" do
    it "should let me reassign attributes" do
      User.attr_encodable :id => :identifier
      @user.as_json.should == {'identifier' => @user.id}
    end

    it "should let me reassign attributes alongside regular attributes" do
      User.attr_encodable :login, :last_name, :id => :identifier
      @user.as_json.should == {'identifier' => 1, 'login' => 'flipsasser', 'last_name' => 'sasser'}
    end

    it "should let me reassign :methods" do
      User.attr_encodable :foobar => :w00t
      @user.as_json.should == {'w00t' => 'baz'}
    end

    it "should let me reassign :include" do
      User.attr_encodable :permissions => :deez_permissions
      @user.as_json.should == {'deez_permissions' => @user.permissions.as_json}
    end

    it "should let me specify a prefix to a set of attr_encodable's" do
      User.attr_encodable :id, :first_name, :foobar, :permissions, :prefix => :t
      @user.as_json.should == {'t_id' => @user.id, 't_first_name' => @user.first_name, 't_foobar' => 'baz', 't_permissions' => @user.permissions.as_json}
    end
  end

  it "should propagate down subclasses as well" do
    User.attr_encodable :name
    class SubUser < User; end
    SubUser.unencodable_attributes.should == User.unencodable_attributes
  end
end
