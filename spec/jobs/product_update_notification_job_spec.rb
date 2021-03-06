require 'spec_helper'

describe ProductUpdateNotificationJob do
  before do
    @product_type = FactoryGirl.create(:product_type)
    @category = FactoryGirl.create(:category)
    @subcategory = FactoryGirl.create(:subcategory)
    @product = FactoryGirl.create(:product)
    @image = FactoryGirl.create(:image)
  end

  describe "perform" do
    it "should not email any users if no users have downloaded the product" do
      expect(Download).to receive(:update_all_users_who_have_downloaded_at_least_once).and_return([])
      expect_any_instance_of(ProductUpdateNotificationJob).to_not receive(:email_users_about_updated_instructions)
      ProductUpdateNotificationJob.new('2345',{'product_id' => @product.id, 'message' => 'Test'}).perform
    end

    it 'should email users if users have previously downloaded the product' do
      expect(Download).to receive(:update_all_users_who_have_downloaded_at_least_once).and_return([FactoryGirl.create(:user)])
      expect_any_instance_of(ProductUpdateNotificationJob).to receive(:email_users_about_updated_instructions)
      ProductUpdateNotificationJob.new('2345',{'product_id' => @product.id, 'message' => 'Test'}).perform
    end
  end

  describe "email_users_about_updated_instructions" do
    it "should send an email to each user who wants to get one" do
      users = []
      users << FactoryGirl.create(:user)
      expect(UpdateMailer).to receive(:updated_instructions).once.and_return(Mail::Message.new(from: 'fake', to: 'fake'))
      expect_any_instance_of(Mail::Message).to receive(:deliver).once.and_return(true)
      ProductUpdateNotificationJob.new('4567',{'product_id' => @product.id, 'message' => 'Test'}).
          email_users_about_updated_instructions(users, @product.id, 'Test')
    end
  end
end