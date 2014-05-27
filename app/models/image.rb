class Image < ActiveRecord::Base
  belongs_to :product
  mount_uploader :url, ImageUploader

  attr_accessible :category_id, :location, :product_id, :url, :url_cache, :remove_url

  #def initialize

  #end

end
