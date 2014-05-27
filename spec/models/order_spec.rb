require 'spec_helper'

describe Order do
  before do
    @product_type = FactoryGirl.create(:product_type)
  end
  describe "has_physical_product?" do
    it "should return false if the order doesn't include a physical product" do
      @category = FactoryGirl.create(:category)
      @subcategory = FactoryGirl.create(:subcategory)
      product1 = FactoryGirl.create(:product)
      li1 = LineItem.new :product_id => product1.id, :quantity => 1, :total_price => 5
      order = Order.new
      order.line_items << li1
      order.has_physical_item?.should == false
    end

    it "should return true if the order includes a physical product" do
      @product_type = FactoryGirl.create(:product_type, :name => 'Models', :digital_product => false)
      @category = FactoryGirl.create(:category)
      @subcategory = FactoryGirl.create(:subcategory)
      FactoryGirl.create(:product)
      product2 = FactoryGirl.create(:physical_product, :product_type_id => @product_type.id)
      li1 = LineItem.new :product_id => product2.id, :quantity => 1, :total_price => 5
      order = Order.new
      order.line_items << li1

      order.has_physical_item?.should == true
    end
  end

  describe "self.shipping_status_not_complete" do
    it "should get records where shipping status is not complete" do
      order1 = FactoryGirl.create(:order, {:shipping_status => '1'})
      order2 = FactoryGirl.create(:order, {:shipping_status => '0'})
      order3 = FactoryGirl.create(:order, {:shipping_status => '1'})

      orders = Order.shipping_status_not_complete
      orders.length.should == 2
    end
  end

  describe "self.shipping_status_complete" do
    it "should get records where shipping status is complete" do
      order1 = FactoryGirl.create(:order, {:shipping_status => '1'})
      order2 = FactoryGirl.create(:order, {:shipping_status => '0'})
      order3 = FactoryGirl.create(:order, {:shipping_status => '0'})

      orders = Order.shipping_status_complete
      orders.length.should == 2
    end
  end

  describe "add_line_items_from_cart" do
    it "should add line items from cart" do
      @category = FactoryGirl.create(:category)
      @subcategory = FactoryGirl.create(:subcategory)
      cart = Cart.new
      cart.add_product(FactoryGirl.create(:product))
      cart.add_product(FactoryGirl.create(:product,
                               :name => "Grader",
                               :product_type_id => @product_type.id,
                               :product_code => "WC002",
                               :description => "Winter Village Grader... are you kidding? w00t! Plow your winter village to the ground and then flatten it out with this sweet grader.",
                               :price => "5.00",
                               :ready_for_public => "t"
                       ))

      order = Order.new
      order.add_line_items_from_cart(cart)

      order.line_items.should have(2).items
    end
  end

  describe "total_price" do
    it "should return a total price" do
      li1 = LineItem.new :product_id => 1, :quantity => 1, :total_price => 5
      li2 = LineItem.new :product_id => 2, :quantity => 1, :total_price => 10
      order = Order.new
      order.line_items << li1
      order.line_items << li2
      order.total_price.should == 15.0
    end
  end

  it "should delete related line_items when it gets deleted" do
    @order = FactoryGirl.create(:order_with_line_items)

    lambda { @order.destroy }.should change(LineItem, :count).from(1).to(0)
  end

  describe "Order.all_transactions_for_month" do
    it "should return an array o arrays with each array representing a single transaction, with all transactions for a month" do
      @category = FactoryGirl.create(:category)
      @subcategory = FactoryGirl.create(:subcategory)
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
      transactions = Order.all_transactions_for_month(Date.today.month,Date.today.year)
      transactions.should == [["charlie_brown@peanuts.com", "blarney", "blar", "COMPLETED", Date.today.strftime("%m/%d/%Y"), "CB001 Colonial Revival House", 1, "9.99"]]
    end
  end

  describe "Order.transaction_csv" do
    it "should take transactions fed in and return a csv" do
      @category = FactoryGirl.create(:category)
      @subcategory = FactoryGirl.create(:subcategory)
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
      transactions = Order.all_transactions_for_month(Date.today.month,Date.today.year)
      transaction_csv = Order.transaction_csv(transactions)
      transaction_csv.should == "Email,Transaction ID,Request ID,Status,Date,Product,Qty,Total Price\ncharlie_brown@peanuts.com,blarney,blar,COMPLETED,#{Date.today.strftime("%m/%d/%Y")},CB001 Colonial Revival House,1,9.99\n"
    end
  end

  describe "get_download_links" do
    context 'the product in question includes instructions' do
      it "should return an array of urls with query strings, paired with descriptive titles for each link" do
        @category = FactoryGirl.create(:category)
        @subcategory = FactoryGirl.create(:subcategory)
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        html_list = FactoryGirl.create(:html_parts_list, :product_id => @product.id)
        xml_list = FactoryGirl.create(:xml_parts_list, :product_id => @product.id)
        @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
        SecureRandom.should_receive(:hex).and_return('fake_hex')

        links = @order.get_download_links
        links.should eq([["CB001 Colonial Revival House HTML Parts List", "/guest_download_parts_list/1/1"], ["CB001 Colonial Revival House XML Parts List for Bricklink Wanted List Feature", "/guest_download_parts_list/2/1"], ["CB001 Colonial Revival House PDF", "/guest_download?id=#{@user.guid}&token=fake_hex"]])
      end
    end

    context 'the product in question does not include instructions' do
      it 'should return an empty array' do
        @product_type = FactoryGirl.create(:product_type, :name => 'Crafts')
        @category = FactoryGirl.create(:category)
        @subcategory = FactoryGirl.create(:subcategory)
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product, :product_type_id => @product_type.id)
        @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)

        links = @order.get_download_links
        links.should eq([])
      end
    end
  end

  describe 'get_link_to_downloads' do
    context 'there is no transaction ID in the order record' do
      it 'should return a link to the download_error_page' do
        @category = FactoryGirl.create(:category)
        @subcategory = FactoryGirl.create(:subcategory)
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product, :product_type_id => @product_type.id)
        @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
        @order.transaction_id = nil
        link = @order.get_link_to_downloads

        link.should eq('http://localhost:3000/download_link_error')
      end
    end

    context 'there is no request ID in the order record' do
      it 'should return a link to the download_error_page' do
        @category = FactoryGirl.create(:category)
        @subcategory = FactoryGirl.create(:subcategory)
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product, :product_type_id => @product_type.id)
        @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
        @order.request_id = nil
        link = @order.get_link_to_downloads

        link.should eq('http://localhost:3000/download_link_error')
      end
    end

    context 'there is a transaction ID and request ID in the order record' do
      it 'should return a link to guest_downloads with a query string' do
        @category = FactoryGirl.create(:category)
        @subcategory = FactoryGirl.create(:subcategory)
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product, :product_type_id => @product_type.id)
        @order = FactoryGirl.create(:order_with_line_items, :created_at => Date.today, :user_id => @user.id)
        link = @order.get_link_to_downloads

        link.should eq('http://localhost:3000/guest_downloads?tx_id=blarney&conf_id=blar')
      end
    end
  end
end
