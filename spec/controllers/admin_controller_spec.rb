require 'spec_helper'

describe AdminController do
  before do
    @radmin ||= FactoryGirl.create(:radmin)
    @product_type = FactoryGirl.create(:product_type)
  end

  describe 'gift_instructions' do
    it 'should create a new order with status = GIFT if could not find an order with status = GIFT' do
      user = FactoryGirl.create(:user)
      category = FactoryGirl.create(:category)
      subcategory = FactoryGirl.create(:subcategory)
      product = FactoryGirl.create(:product)
      sign_in @radmin

      expect(lambda { post :gift_instructions, format: :json, gift: {'user_id' => user.id, 'product_id' => product.id} }).to change{Order.count}.by(1)
      expect(assigns(:order).status).to eq 'GIFT'
    end

    it 'should destroy the line_item for an order if the user owns the product via gifting' do
      user = FactoryGirl.create(:user)
      category = FactoryGirl.create(:category)
      subcategory = FactoryGirl.create(:subcategory)
      product = FactoryGirl.create(:product)
      order = FactoryGirl.create(:order, status: 'GIFT')
      line_item = FactoryGirl.create(:line_item, order_id: order.id, product_id: product.id)
      sign_in @radmin

      expect(lambda { post :gift_instructions, format: :json, gift: {'user_id' => user.id, 'product_id' => product.id} }).to change{LineItem.count}.by(-1)
    end

    it 'should add a line_item to the order if one does not already exist' do
      user = FactoryGirl.create(:user)
      category = FactoryGirl.create(:category)
      subcategory = FactoryGirl.create(:subcategory)
      product = FactoryGirl.create(:product)
      order = FactoryGirl.create(:order, status: 'GIFT')
      sign_in @radmin

      expect(lambda { post :gift_instructions, format: :json, gift: {'user_id' => user.id, 'product_id' => product.id} }).to change{LineItem.count}.by(1)
    end
  end

  describe 'transactions_by_month' do
    it "should return all transactions for a given month" do
      user = FactoryGirl.create(:user)
      category = FactoryGirl.create(:category)
      subcategory = FactoryGirl.create(:subcategory)
      product = FactoryGirl.create(:product)
      order = FactoryGirl.create(:order_with_line_items, :user_id => user.id, :created_at => Time.now.utc.to_date)
      order2 = FactoryGirl.create(:order_with_line_items, :created_at => '2010-01-01', :user_id => user.id)
      sign_in @radmin
      get :transactions_by_month, :date => Time.now.utc.to_date.strftime("%Y-%m-%d"), :format => 'csv'

      expect(assigns(:transactions).size).to eq(1)
    end
  end

  describe "update_order_shipping_status" do
    it "should update the orders shipping status" do
      order = FactoryGirl.create(:order, :shipping_status => '0')
      sign_in @radmin
      put :update_order_shipping_status, {:order_id => order.id, :shipping_status => '1'}

      expect(assigns(:order).shipping_status).to eq(1)
      expect(response).to redirect_to('/order_fulfillment')
    end
  end

  describe "order_fulfillment" do
    it "should set up the order fulfillment page" do
      order1 = FactoryGirl.create(:order, :shipping_status => '0')
      order2 = FactoryGirl.create(:order, :shipping_status => '1')
      order3 = FactoryGirl.create(:order, :shipping_status => '1')
      sign_in @radmin

      get :order_fulfillment

      expect(assigns(:completed_orders).size).to eq(1)
      expect(assigns(:incomplete_orders).size).to eq(2)
    end
  end

  describe "complete_order" do
    it "should set the orders status to COMPLETED and redirect back" do
      order = FactoryGirl.create(:order, :status => 'incomplete')
      request.env['HTTP_REFERER'] = '/'
      sign_in @radmin
      post :complete_order, :order => {:id => order.id}

      expect(assigns(:order).status).to eq('COMPLETED')
      expect(response).to redirect_to('/')
    end
  end

  describe "maintenance_mode" do
    it "should render the maintenance mode page" do
      @switch = FactoryGirl.create(:switch)
      sign_in @radmin
      get :maintenance_mode

      expect(response).to render_template('maintenance_mode')
      expect(assigns(:mm_switch).switch).to eq('maintenance_mode')
    end
  end

  describe "switch_maintenance_mode" do
    it "should switch maintenance mode on and off" do
      @switch = FactoryGirl.create(:switch)
      sign_in @radmin
      post :switch_maintenance_mode

      expect(assigns(:mm_switch).switch_on).to eq(true)

      post :switch_maintenance_mode

      expect(assigns(:mm_switch).switch_on).to eq(false)
    end
  end

  describe "sales_report" do
    it "should render the sales report page" do
      sign_in @radmin
      get :sales_report

      expect(response).to render_template('sales_report')
    end
  end

  describe "sales_report_monthly_stats" do
    it "should return a hash of stat summaries for a multiple month report" do
      @sales_report = FactoryGirl.create(:sales_report, :report_date => "#{Time.now.utc.to_date.year}-#{Time.now.utc.to_date.month}-01")
      @sales_summary = FactoryGirl.create(:sales_summary, :sales_report_id => @sales_report.id, :product_id => 1)
      sign_in @radmin
      post :sales_report_monthly_stats, :start_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, :end_date => {'month' => Time.now.utc.to_date.next_month.month, 'year' => Time.now.utc.to_date.next_month.year}, format: :js

      expect(assigns(:summaries)).to eq({"1"=>{"qty"=>1, "revenue"=>BigDecimal.new('10')}})
    end

    it "should return a hash of stat summaries for a single month report when the report has been completed" do
      @sales_report = FactoryGirl.create(:sales_report, :completed => true, :report_date => "#{Time.now.utc.to_date.year}-#{Time.now.utc.to_date.month}-01")
      @sales_summary = FactoryGirl.create(:sales_summary, :sales_report_id => @sales_report.id, :product_id => 1)
      sign_in @radmin
      post :sales_report_monthly_stats, :start_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, :end_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, format: :js

      expect(assigns(:summaries)).to eq({"1"=>{"qty"=>1, "revenue"=>BigDecimal.new('10')}})
    end

    it "should regenerate a completed report if the user clicks the 'Force Regeneration' button" do
      @sales_report = FactoryGirl.create(:sales_report, :completed => true, :report_date => "#{Time.now.utc.to_date.year}-#{Time.now.utc.to_date.month}-01")
      @sales_summary = FactoryGirl.create(:sales_summary, :sales_report_id => @sales_report.id, :product_id => 1)
      @order = FactoryGirl.create(:order_with_line_items)
      sign_in @radmin
      post :sales_report_monthly_stats, :start_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, :end_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, :commit => 'Force Regeneration', format: :js

      expect(assigns(:summaries)['1']['qty']).to eq(1)
      expect(assigns(:summaries)['1']['revenue'].to_f).to eq(10.0)
    end

    it "should automatically regenerate a report if the report is for the current month, which is of course not complete yet" do
      @sales_report = FactoryGirl.create(:sales_report, :completed => false, :report_date => "#{Time.now.utc.to_date.year}-#{Time.now.utc.to_date.month}-01")
      @sales_summary = FactoryGirl.create(:sales_summary, :sales_report_id => @sales_report.id, :product_id => 1)
      @order = FactoryGirl.create(:order_with_line_items)
      sign_in @radmin
      post :sales_report_monthly_stats, :start_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, :end_date => {'month' => Time.now.utc.to_date.month, 'year' => Time.now.utc.to_date.year}, format: :js

      expect(assigns(:summaries)['1']['qty']).to eq(1)
      expect(assigns(:summaries)['1']['revenue'].to_f).to eq(10.0)
    end

    it "should mark a sales report as completed if the month is in the past" do
      @sales_report = FactoryGirl.create(:sales_report, :completed => false, :report_date => "#{Time.now.utc.to_date.prev_month.year}-#{Time.now.utc.to_date.prev_month.month}-01")
      @sales_summary = FactoryGirl.create(:sales_summary, :sales_report_id => @sales_report.id, :product_id => 1)
      @order = FactoryGirl.create(:order_with_line_items)
      sign_in @radmin
      post :sales_report_monthly_stats, :start_date => {'month' => Time.now.utc.to_date.prev_month.month, 'year' => Time.now.utc.to_date.prev_month.year}, :end_date => {'month' => Time.now.utc.to_date.prev_month.month, 'year' => Time.now.utc.to_date.prev_month.year}, format: :js

      expect(assigns(:report).completed).to eq(true)
    end
  end

  describe "become" do
    it "should login the user given the user's ID" do
      @user = FactoryGirl.create(:user)
      sign_in @radmin
      get :become, :id => @user.id

      @user = User.find(@user.id)
      expect(@user.sign_in_count).to eq(1)
    end
  end

  describe "find_user" do
    it "should find the user given the user's email address" do
      sign_in @radmin
      user = FactoryGirl.create(:user)
      xhr :get, :find_user, email: user.email, user: {email: user.email}, format: :js

      expect(assigns(:user).id).to eq(user.id)
    end
  end

  describe "admin_profile" do
    it "should return the admin's profile given the radmin's ID" do
      sign_in @radmin
      get "admin_profile", :id => @radmin.id
      expect(assigns(:radmin).id).to eq(@radmin.id)
    end
  end

  describe "update_admin_profile" do
    it "given valid params, should update the admin's profile" do
      sign_in @radmin
      put :update_admin_profile, :id => @radmin.id,:radmin => {:email => 'silly@billy.com'}
      @radmin = Radmin.find(@radmin.id)

      expect(assigns(:radmin).errors.messages).to eq({})
      expect(flash[:notice]).to eq("Profile was successfully updated.")
      expect(@radmin.email).to eq('silly@billy.com')
    end

    it "with an invalid password, should not update the admin's profile" do
      sign_in @radmin
      put :update_admin_profile, :id => @radmin.id, :radmin => {:current_password => "blar"}

      expect(assigns(:radmin).errors.messages).to eq({:current_password=>["is invalid."]})
    end

    it "with an invalid email address, should not update the admin's profile" do
      sign_in @radmin
      put :update_admin_profile, :id => @radmin.id, :radmin => {:email => "6"}

      expect(assigns(:radmin).errors.messages).to eq({:email => ["is invalid"]})
    end
  end

  describe "change_user_status" do
    it "should change user's status" do
      @user = FactoryGirl.create(:user, :account_status => 'A')
      sign_in @radmin
      xhr :get, :change_user_status, :email => @user.email, :user => {:email => @user.email, :account_status => 'C'}, :format => :js
      @user = User.find(@user.id)

      expect(@user.account_status).to eq('C')
    end
  end

  describe "order" do
    it "should return an order given the order's ID" do
      order = FactoryGirl.create(:order)
      sign_in @radmin
      get :order, :id => order.id

      expect(assigns(:order).id).to eq(order.id)
    end
  end

  describe "updates_users_download_count" do
    it "should set up products in a useful way" do
      FactoryGirl.create(:category)
      FactoryGirl.create(:subcategory)
      @product = FactoryGirl.create(:product)
      sign_in @radmin
      get :update_users_download_counts

      expect(assigns(:products)).to eq([["#{@product.product_code} #{@product.name}", @product.id]])
    end
  end

  describe "update_downloads_for_user" do
    it "should flash a happy message if Resque.enqueue returns true" do
      sign_in @radmin
      allow(ProductUpdateNotificationJob).to receive(:create).and_return('1234')
      get :update_downloads_for_user, :user => {:model => 1}

      expect(flash[:notice]).to eq("Sending product update emails")
    end

    it "should flash a concerned message if Resque.enqueue returns nil" do
      sign_in @radmin
      allow(ProductUpdateNotificationJob).to receive(:create).and_return(nil)
      get :update_downloads_for_user, :user => {:model => 1}

      expect(flash[:notice]).to eq("Couldn't queue mail jobs. Check out /jobs and see what's wrong")
    end
  end

  describe "send_new_product_notification" do
    it "should flash a happy message if Resque.enqueue returns true" do
      sign_in @radmin
      allow(NewProductNotificationJob).to receive(:create).and_return('1234')
      post :send_new_product_notification, :email => {'product_id' => 1, 'optional_message' => 'Hi!'}

      expect(flash[:notice]).to eq('Sending new product emails')
    end

    it "should flash a concerned message if Resque.enqueue returns nil" do
      sign_in @radmin
      allow(NewProductNotificationJob).to receive(:create).and_return(nil)
      post :send_new_product_notification, :email => {'product_id' => 1, 'optional_message' => 'Hi!'}

      expect(flash[:alert]).to eq("Couldn't queue email jobs. Check out /jobs and see what's wrong")
    end
  end
end
