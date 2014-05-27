require 'spec_helper'

describe Product do
  before do
    @product_type = FactoryGirl.create(:product_type, :digital_product => true)
    @product_type2 = FactoryGirl.create(:product_type, :name => 'Models', :digital_product => false)
    @category = FactoryGirl.create(:category)
    @subcategory = FactoryGirl.create(:subcategory)
  end

  it "should find live products from the same category" do
    category = FactoryGirl.create(:category, :name => "blah")
    products = [FactoryGirl.create(:product),
                FactoryGirl.create(:product,
                                   :name => "Grader",
                                   :product_code => "CV002",
                                   :description => "Winter Village Grader... are you kidding? w00t! Plow your winter village to the ground and then flatten it out with this sweet grader.",
                                   :price => "5.00",
                                   :ready_for_public => "f"),
                FactoryGirl.create(:product,
                                   :name => "Zeppelin",
                                   :product_code => "CV003",
                                   :description => "Winter Village Zeppelin... are you kidding? w00t! Flatten London with this Winter Village Zeppelin, then land in a nearby village and celebrate Christmas.",
                                   :price => "5.00",
                                   :ready_for_public => "t"),
                FactoryGirl.create(:product,
                                   :name => "Chocolate Factory",
                                   :product_code => "CB004",
                                   :description => "Winter Village Chocolate Factory... are you kidding? w00t! Charlie won't believe his eyes when he gets to celebrate Christmas inside a chocolate factory... with oompah-loompahs.",
                                   :price => "5.00",
                                   :ready_for_public => "t",
                                   :category_id => category.id)
    ]
    @product = products[1]
    products = @product.find_live_products_from_same_category
    products.length.should == 2
  end

  it "should only find models that are ready for the public" do
    #First product is ready for public, 2nd one is not, so there should only be 1 product
    products = [FactoryGirl.create(:product),
                 FactoryGirl.create(:product,
                         :name => "Grader",
                         :product_code => "WC002",
                         :description => "Winter Village Grader... are you kidding? w00t! Plow your winter village to the ground and then flatten it out with this sweet grader.",
                         :price => "5.00",
                         :ready_for_public => "f"
                 )
    ]
    @products = Product.find_products_for_sale
    @products.should have(1).item
  end

  it "should delete related images" do
    @product = FactoryGirl.create(:product)
    @image = FactoryGirl.create(:image)

    lambda { @product.destroy }.should change(Image, :count)
  end

  it "is valid with valid attributes" do
    @product = FactoryGirl.create(:product)
    @product.should be_valid
  end

  it "is invalid if product_code is not unique" do
    @products = [FactoryGirl.create(:product),
                 FactoryGirl.create(:product,
                         :name => "Grader",
                         :product_code => "WC002",
                         :product_type_id => @product_type.id,
                         :description => "Winter Village Grader... are you kidding? w00t! Plow your winter village to the ground and then flatten it out with this sweet grader.",
                         :price => "5.00",
                         :ready_for_public => "t"
                 )
    ]
    product = Product.new(:price => 5,
                          :product_code => 'WC002',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "blah blah blah",
                          :tweet => "Hello tweeters.",
                          :ready_for_public => true,
                          :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
    )
    product.errors_on(:product_code).should == ["has already been taken"]
  end

  it "is invalid if name is not unique" do
    @products = [FactoryGirl.create(:product),
                 FactoryGirl.create(:product,
                         :name => "Grader",
                         :product_code => "WC002",
                         :product_type_id => @product_type.id,
                         :description => "Winter Village Grader... are you kidding? w00t! Plow your winter village to the ground and then flatten it out with this sweet grader.",
                         :price => "5.00",
                         :ready_for_public => "t"
                 )
    ]
    product = Product.new(:price => 5,
                          :product_code => 'XX001',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "Grader",
                          :tweet => "Hello tweeters.",
                          :ready_for_public => true,
                          :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
    )
    product.errors_on(:name).should == ["has already been taken"]
  end

  it "is invalid with a description that's too short" do
    product = Product.new(:price => 5,
                          :product_code => 'XX001',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "blah blah blah",
                          :tweet => "Hello tweeters.",
                          :ready_for_public => true,
                          :description => "It's pretty awesome."
    )
    product.errors_on(:description).should == ["is too short (minimum is 100 characters)"]
  end

  it "is invalid with a tweet that's too long" do
    product = Product.new(:price => 5,
                          :product_code => 'XX001',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "blah blah blah",
                          :tweet => "Hello tweeters, blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah.",
                          :ready_for_public => true,
                          :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
    )
    product.errors_on(:tweet).should == ["is too long (maximum is 97 characters)"]
  end

  it "is invalid if price is not a number" do
    product = Product.new(:price => "ralph",
                          :product_code => 'XX001',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "blah blah blah",
                          :tweet => "Hello tweeters.",
                          :ready_for_public => true,
                          :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
              )
    product.errors_on(:price).should include(" Hey... Don't you want to make some money on this?")
  end

  it "should be invalid if it is free and has a price > 0" do
    @product = FactoryGirl.build(:free_product, :price => 10)

    @product.errors_on(:price).should include(" Freebies should be $0")
  end

  it "should be valid if it is free and has a price of 0" do
    @product = FactoryGirl.create(:free_product)

    @product.should be_valid
  end

  it "should be invalid if it has a product_code that doesn't match the pattern for Instructions" do
    @product = FactoryGirl.build(:product, :product_code => 'doh')

    @product.errors_on(:product_code).should include("Instruction product codes must follow the pattern CB002.")
  end

  it "should be invalid if it has a product_code that doesn't match the pattern for Models" do
    @product1 = FactoryGirl.create(:product)
    @product = FactoryGirl.build(:product, :product_type_id => @product_type2.id, :name => 'fake model', :product_code => 'doh')

    @product.errors_on(:product_code).should include("Model product codes must follow the pattern CB002M.")
  end

  it "should be invalid if it has a product_code that doesn't match the pattern for Kits" do
    @product_type3 = FactoryGirl.create(:product_type, :name => 'Kits', :digital_product => false)
    @product1 = FactoryGirl.create(:product)
    @product = FactoryGirl.build(:product, :product_type_id => @product_type3.id, :name => 'fake kit', :product_code => 'doh')

    @product.errors_on(:product_code).should include("Kit product codes must follow the pattern CB002K.")
  end

  it "should be invalid if there is no base model with the same base product_code for Models" do
    @product1 = FactoryGirl.create(:product)
    @product = FactoryGirl.build(:product, :product_type_id => @product_type2.id, :name => 'fake model', :product_code => 'HH001M')

    @product.errors_on(:product_code).should include("Model product codes must have a base model with a product code of HH001")
  end

  it "should be invalid if there is no base model with the same base product_code for Kits" do
    @product_type3 = FactoryGirl.create(:product_type, :name =>"Kits")
    @product1 = FactoryGirl.create(:product)
    @product = FactoryGirl.build(:product, :product_type_id => @product_type3.id, :name => 'fake kit', :product_code => 'HH001K')

    @product.errors_on(:product_code).should include("Kit product codes must have a base model with a product code of HH001")
  end

  describe "destroy" do
    it "should switch the ready_for_public flag to false if there are existing orders for the product" do
      @product = FactoryGirl.create(:product)
      @order = FactoryGirl.create(:order)
      @line_item = FactoryGirl.create(:line_item, :product_id => @product.id, :order_id => @order.id)

      lambda{@product.destroy}.should change(@product, :ready_for_public).from(true).to(false)
    end

    it "should not destroy the product if there are existing orders for the product" do
      @product = FactoryGirl.create(:product)
      @order = FactoryGirl.create(:order)
      @line_item = FactoryGirl.create(:line_item, :product_id => @product.id, :order_id => @order.id)

      lambda { @product.destroy }.should_not change(Product, :count)
    end

    it "should delete the product if there are no orders for the product" do
      @product = FactoryGirl.create(:product)

      lambda { @product.destroy }.should change(Product, :count)
    end
  end

  it "should not let the radmin make a product live if the pdf has not been uploaded" do
    @product = Product.new(:price => 5,
                          :product_code => 'XX001',
                          :product_type_id => @product_type.id,
                          :subcategory_id => 1,
                          :category_id => 1,
                          :name => "blah blah blah",
                          :tweet => "Hello tweeters.",
                          :ready_for_public => true,
                          :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf.",
                          :pdf => nil
    )

    @product.errors_on(:ready_for_public).should == [": Can't allow you to make a product live before you upload the PDF."]
  end

  describe "decrement_quantity" do
    it "should decrement the quantity of a physical product" do
      @product = Product.new(:price => "5",
                            :product_code => 'XX001',
                            :product_type_id => @product_type2.id,
                            :subcategory_id => 1,
                            :category_id => 1,
                            :name => "blah blah blah",
                            :tweet => "Hello tweeters.",
                            :ready_for_public => true,
                            :quantity => '5',
                            :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
      )
      lambda { @product.decrement_quantity(2) }.should change(@product, :quantity).from(5).to(3)
    end

    it "should not decrement the quantity of a digital product" do
      @product = Product.new(:price => "5",
                             :product_code => 'XX001',
                             :product_type_id => @product_type.id,
                             :subcategory_id => 1,
                             :category_id => 1,
                             :name => "blah blah blah",
                             :tweet => "Hello tweeters.",
                             :ready_for_public => true,
                             :quantity => '1',
                             :description => "asdf asd asd fsdf asdfas asfjh alsdjf lasfj lasjd flkasjdflajs flasjdflasdlk jlksadj flasj flkasjd flaskdjf las djflkas fjlksa jlksadjf."
      )
      lambda { @product.decrement_quantity(2) }.should_not change(@product, :quantity)
    end
  end

  describe "out_of_stock?" do
    it "should return false if quantity > 0" do
      @base_product = FactoryGirl.create(:product, :quantity => 1, :product_type_id => @product_type.id, :product_code => 'XX111')
      @product = FactoryGirl.create(:product, :quantity => 2, :product_type_id => @product_type2.id, :product_code => 'XX111M', :name => 'fake product')
      @product.out_of_stock?.should == false
    end

    it "should return true if quantity is 0" do
      @product_type3 = FactoryGirl.create(:product_type, :name => 'Kits', :digital_product => false)
      @base_product = FactoryGirl.create(:product, :quantity => 1, :product_type_id => @product_type.id, :product_code => 'XX111')
      @product = FactoryGirl.create(:product, :quantity => 0, :product_type_id => @product_type3.id, :product_code => 'XX111K', :name => 'fake product')
      @product.out_of_stock?.should == true
    end
  end

  describe "base_product_code" do
    it "should pick out the base product code when passed a product code" do
      @base_product = FactoryGirl.create(:product, :product_type_id => @product_type.id, :product_code => 'XX001')
      @product = FactoryGirl.create(:product, :product_type_id => @product_type2.id, :product_code => 'XX001M', :name => 'fake product')
      @product.base_product_code('XX045C').should == 'XX045'
    end

    it "should pick out the base product code using the records product_code" do
      @base_product = FactoryGirl.create(:product, :product_type_id => @product_type.id, :product_code => 'XX001')
      @product = FactoryGirl.create(:product, :product_type_id => @product_type2.id, :product_code => 'XX001M', :name => 'fake product')
      @product.base_product_code.should == 'XX001'
    end
  end

  describe "find_by_base_product_code" do
    it "should by a product by its base code" do
      @product = FactoryGirl.create(:product, :product_type_id => @product_type.id, :product_code => 'XX001')
      Product.find_by_base_product_code('XX001M').product_code.should == 'XX001'
    end
  end

  describe "find all by price" do
    it "should find all products at a given price point" do
      @product1 = FactoryGirl.create(:product)
      @product2 = FactoryGirl.create(:product, :product_type_id => @product_type.id, :name => 'super fakey', :product_code => 'HH001', :price => 10)
      @product3 = FactoryGirl.create(:product, :product_type_id => @product_type.id, :name => 'free fakey', :product_code => 'HH002', :free => 't', :price => 0)

      prods = Product.find_all_by_price(10)
      prods.length.should == 2
      freebies = Product.find_all_by_price('free')
      freebies.length.should == 1
    end
  end

  describe "is_physical_product?" do
    it "should return true if product type is not blank and is != Instructions" do
      @product1 = FactoryGirl.create(:product)
      @product2 = FactoryGirl.create(:physical_product)

      @product2.is_physical_product?.should == true
    end

    it "should return false if product type is Instructions or product type is blank" do
      @product1 = FactoryGirl.create(:product)

      @product1.is_physical_product?.should == false

      #This represents the case where a product is brand new (via the new action) and doesn't have a type yet
      @product2 = FactoryGirl.build(:product, :product_type_id => '', :product_code => 'VV001', :name => 'Fake')

      @product2.is_physical_product?.should == false
    end
  end

  describe "is_digital_product?" do
    it "should return true if product type is not blank and is == Instructions" do
      @product1 = FactoryGirl.create(:product)
      @product2 = FactoryGirl.create(:physical_product)

      @product1.is_digital_product?.should == true
    end

    it "should return false if product type is not Instructions or product type is blank" do
      @product1 = FactoryGirl.create(:product)
      @product2 = FactoryGirl.create(:physical_product, :product_type_id => @product_type2.id)

      @product2.is_digital_product?.should == false

      #This represents the case where a product is brand new (via the new action) and doesn't have a type yet.
      #It gets set to true so that all fields are displayed on the product form
      @product3 = FactoryGirl.build(:product, :product_type_id => '', :product_code => 'VV001', :name => 'Fake')

      @product3.is_digital_product?.should == true
    end
  end
end