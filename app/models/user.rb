require 'digest/sha1'

class User < ActiveRecord::Base
  acts_as_annotation_source
  include SavageBeast::UserInit

  acts_as_tagger
    
  belongs_to :person
  #validates_associated :person

  has_many :protocols, :as=>:contributor
  has_many :data_files, :as=>:contributor
  has_many :models,:as=>:contributor
  has_many :presentations,:as=>:contributor
  has_many :events, :as => :contributor
  has_many :publications, :as => :contributor

  has_many :investigations,:as=>:contributor
  has_many :studies,:as=>:contributor

  #restful_authentication plugin generated code ...
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  #validates_presence_of     :login, :email - removed requirement on email
  #validates_length_of       :email,    :within => 3..100
  
  validates_presence_of     :login,                      :unless => :using_openid?
  validates_presence_of     :password,                   :if => :password_required?, :unless => :using_openid?
  validates_presence_of     :password_confirmation,      :if => :password_required?, :unless => :using_openid?
  validates_length_of       :password, :within => 4..40, :if => :password_required?, :unless => :using_openid?
  validates_confirmation_of :password,                   :if => :password_required?, :unless => :using_openid?
  validates_length_of       :login,    :within => 3..40, :unless => :using_openid?
  
  validates_uniqueness_of   :login, :case_sensitive => false
  validates_uniqueness_of   :openid, :case_sensitive => false, :allow_nil => true
  
  before_save :encrypt_password
  before_create :make_activation_code 
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :openid
    
  has_many :favourite_groups, :dependent => :destroy
  
  named_scope :not_activated,:conditions=>['activation_code IS NOT NULL']
  named_scope :without_profile,:conditions=>['person_id IS NULL']  
  
  acts_as_uniquely_identifiable

  after_create :queue_update_auth_table

  def queue_update_auth_table
    AuthLookupUpdateJob.add_items_to_queue self
  end

  cattr_accessor :current_user

  def can_manage_types?
    unless Seek::Config.type_managers_enabled
      return false
    end

    case Seek::Config.type_managers
      when "admins"
      if User.admin_logged_in?
        return true
      else
        return false
      end
      when "pals"
      if User.admin_logged_in? || User.pal_logged_in?
        return true
      else
        return false
      end
      when "users"
      return true
      when "none"
      return false
    end
  end

  def self.admin_logged_in?
    self.logged_in_and_registered? && self.current_user.person.is_admin?
  end

  def self.project_manager_logged_in?
    self.logged_in_and_registered? && self.current_user.person.is_project_manager?
  end

  #a person can be logged in but not fully registered during
  #the registration process whilst selecting or creating a profile
  def self.logged_in_and_registered?
    self.logged_in? && self.current_user.person
  end

  def self.logged_in_and_member?
    self.logged_in? && self.current_user.person.try(:member?)
  end

  def self.logged_in?
    self.current_user
  end

  def self.pal_logged_in?
    self.logged_in_and_registered? && self.current_user.person.is_pal?
  end

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  def assets
    protocols | models | data_files
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ?', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  # performs a simple conversion from an array of user's project instances into a hash { <project_id> => <project_name>, [...] }
  def generate_own_project_id_name_hash
    return Hash[*self.person.projects.collect{|p|; [p.id, p.name];}.flatten]
  end  
  
  # returns a 'whitelist' favourite group for the user (or 'nil' if not found)
  def get_whitelist
    return FavouriteGroup.find(:first, :conditions => { :user_id => self.id, :name => FavouriteGroup::WHITELIST_NAME } )
  end
  
  # returns a 'blacklist' favourite group for the user (or 'nil' if not found)
  def get_blacklist
    return FavouriteGroup.find(:first, :conditions => { :user_id => self.id, :name => FavouriteGroup::BLACKLIST_NAME } )
  end

  #required for savage beast plugin
  #see http://www.williambharding.com/blog/rails/savage-beast-23-a-rails-22-23-message-forum-plugin/
  def admin?
    is_admin?
  end

  def currently_online
    false
  end

  def display_name
    person.name
  end
  
  def using_openid?
    !openid.nil?
  end
        
  def is_admin?
    !person.nil? && person.is_admin?
  end

  def is_project_manager?
    !person.nil? && person.is_project_manager?
  end
  
  def can_edit_projects?
    !person.nil? && person.can_edit_projects?
  end
  
  def can_edit_institutions?
    !person.nil? && person.can_edit_institutions?
  end

  def self.with_current_user user
    previous = self.current_user
    self.current_user = user
    begin
      yield
    ensure
      User.current_user = previous
    end
  end

  protected
  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
      
  def password_required?
    crypted_password.blank? || !password.blank?
  end
    
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
    
end

