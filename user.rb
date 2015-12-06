class User < ActiveRecord::Base
  has_secure_password

  has_many :images

  validates_presence_of :email
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create
  validates_uniqueness_of :email, :case_sensitive => false

  before_save :downcase_email
  before_save :generate_token

  def downcase_email
    self.email.downcase!
  end
  
  def generate_token
    self.token = Digest::SHA1::hexdigest([Time.now, rand].join) 
  end
end
