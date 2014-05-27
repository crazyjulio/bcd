class Product < ActiveRecord::Base
  belongs_to :category
  belongs_to :subcategory
  belongs_to :product_type
  has_many :downloads
  has_many :images, :dependent => :destroy
  has_many :parts_lists, :dependent => :destroy
  mount_uploader :pdf, PdfUploader
  accepts_nested_attributes_for :images, :allow_destroy => true
  accepts_nested_attributes_for :parts_lists, :allow_destroy => true

  attr_accessible :category_id, :description, :discount_percentage, :name, :pdf, :pdf_cache,
                  :price, :product_code, :product_type_id, :ready_for_public, :remove_pdf,
                  :subcategory_id, :tweet, :free, :quantity, :alternative_build, :youtube_url, :images_attributes,
                  :parts_lists_attributes

  validates :product_code, :uniqueness => true, :presence => true
  validates :product_type_id, :presence => true
  validates :subcategory_id, :presence => true
  validates :category_id, :presence => true
  validates :description, :presence => true, :length => {:minimum => 100, :maximum => 900}
  validates :price, :presence => true, :numericality => true
  validates :price, :price_greater_than_zero => true
  validates :price, :price_is_zero_for_freebies => true
  validates :product_code, :product_code_matches_pattern => true
  validates :name, :presence => true, :uniqueness => true
  validates :tweet, :length => {:maximum => 97}
  #This line calls a custom validator that looks to make sure that there is a pdf attached to this object before
  #letting this product be made available to the public
  validates :ready_for_public, :pdf_exists => true

  scope :ready, -> {where(ready_for_public: true)}
  scope :in_stock, -> {where("quantity > 0")} #Maybe set up to use only physical products, and not digital products
  scope :instructions, -> {Product.joins(:product_type).where("product_types.name='Instructions'")}
  scope :ready_instructions, -> {ready.instructions}
  scope :sellable_instructions, -> {ready_instructions.where(free: false)}

  def self.find_all_by_price(price)
    price = 0 if price == 'free'
    Product.ready_instructions.where(["price=?",price])
  end

  def self.sort_by_price
    blk = lambda{|h,k| h[k] = Hash.new(&blk)}
    price_groups = Hash.new(&blk)
    products = Product.ready_instructions.order(:price)
    products.each do |product|
      if price_groups.has_key?("#{product.price.to_i}")
        price_groups["#{product.price.to_i}"]["count"] += 1
      else
        price_groups["#{product.price.to_i}"]["count"] = 1
      end
    end
    array = []
    price_groups.each do |price_group|
      array << [price_group[0].to_i,price_group[1]["count"]]
    end
    array
  end

  def self.alternative_builds
    Product.sellable_instructions.where("alternative_build = 't'")
  end

  def self.find_products_for_sale
    #At first, ordering by name will be fine. Eventually I might want to order by popularity. Maybe I can have a script that
    ##runs once a day/week that gets total order of sales and updates a 'total_sales' column in the products table.
    ##Then I can use that for ordering
    Product.ready.where("free != 't' and quantity > 0")
  end

  def self.find_instructions_for_sale
    Product.sellable_instructions
  end
#TODO: Replace/remove these 2:
  def self.find_models_for_sale
    Product.ready.where("quantity > 0 and product_type_id = #{ProductType.find_by_name('Models').id}")
  end

  def self.find_kits_for_sale
    Product.ready.where("quantity > 0 and product_type_id = #{ProductType.find_by_name('Kits').id}")
  end

  def self.freebies
    Product.ready_instructions.where("free = 't'")
  end

  def find_live_products_from_same_category
    Product.ready.where(["free != 't' and quantity >= 1 and category_id = ? and id <> ?", category_id, id]).limit(4)
  end

  #def get_image(image_type)
  #  image = self.images.where("location = '#{image_type} Page'")
  #  image[0].url if !image.blank?
  #end

  def has_orders?
    line_item = LineItem.where(["product_id = ?",self.id]).limit(1)
    line_item.empty? ? false : true
  end

  def destroy
    if self.has_orders?
      #switch ready_for_public flag to 'f', effectively taking the product off the market, but leaving it in the
      #database for reporting purposes
      self.ready_for_public = 'f'
      self.save
    else
      super
    end
  end

  def decrement_quantity(amount)
    unless self.product_type.digital_product?
      self.quantity -= amount
      self.save
    end
  end

  def is_physical_product?
    !is_digital_product?
  end

  def is_digital_product?
    if self.product_type
      return self.product_type.digital_product?
    else
      return true #If there is no product_type, this is a new record, return true to make digital-only fields available in the new form
    end
  end

  def includes_instructions?
    ["Instructions","Kits","Models"].include?(self.product_type.name)
  end

  def quantity_available?(amount)
    self.quantity >= amount
  end

  def out_of_stock?
    self.quantity == 0
  end

  def base_product_code(code = nil)
    if code
      code.match(/^[A-Z]{2}\d{3}/).to_s
    else
      self.product_code.match(/^[A-Z]{2}\d{3}/).to_s
    end
  end

  def self.find_by_base_product_code(product_code)
    product = Product.new
    product = self.find_by_product_code(product.base_product_code(product_code.upcase))
    product
  end

  def is_free?
    self.free
  end

  def code_and_name
    "#{self.product_code} #{self.name}"
  end
  #TODO: Make sure that removing a product not only deletes the image in the database, but also in Amazon S3
end