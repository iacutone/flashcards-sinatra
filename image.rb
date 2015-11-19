class Image < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :file_name, :word

  scope :not_hidden, -> { where('images.hidden' => false) }
end
