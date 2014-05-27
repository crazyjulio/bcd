require 'spec_helper'

describe Download do

  #I want to use this, but it's not working for some reason
  #before do
  #  @user ||= FactoryGirl.create(:user)
  # @product ||= FactoryGirl.create(:product)
  #end
  before do
    @product_type = FactoryGirl.create(:product_type)
    @category = FactoryGirl.create(:category)
    @subcategory = FactoryGirl.create(:subcategory)
  end

  describe "increment_download_count" do
    context 'with a token passed in' do
      it 'should find the download record by user ID and token' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = FactoryGirl.create(:download, :product_id => @product.id, :user_id => @user.id, :count => 2, :download_token => 'token')
        Download.should_receive(:find_by_user_id_and_download_token).and_return(@download)
        @download.increment_download_count(@user, @product.id,'token')
        @dl = Download.find(@download.id)

        @dl.count.should == 3
      end
    end

    it "should increment download count" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = FactoryGirl.create(:download, :product_id => @product.id, :user_id => @user.id, :count => 2)
      Download.should_receive(:find_or_create_by).and_return(@download)
      @download.increment_download_count(@user, @product.id)
      @dl = Download.last

      @dl.count.should == 3
    end
  end

  describe "decrement_remaining_downloads" do
    context 'with a token passed in' do
      it 'should find the download record by user ID and token' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = Download.new(:user_id => @user.id, :product_id => @product.id, :download_token => 'token')
        @download.save!
        Download.should_receive(:find_by_user_id_and_download_token).and_return(@download)
        @download.decrement_remaining_downloads(@user, @product.id,'token')
        @decremented_download = Download.find(@download.id)

        @decremented_download.remaining.should == MAX_DOWNLOADS-1
      end
    end
    it "should decrement download count" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = Download.new(:user_id => @user.id, :product_id => @product.id)
      @download.save!
      Download.should_receive(:find_or_create_by).and_return(@download)
      @download.decrement_remaining_downloads(@user, @product.id)
      @decremented_download = Download.last

      @decremented_download.remaining.should == MAX_DOWNLOADS-1
    end
  end

  describe "add_download_to_user_and_model" do
    it "should add download to user/product if the user has downloaded at least once" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = Download.new(:user_id => @user.id, :product_id => @product.id, :remaining => MAX_DOWNLOADS-1)
      @download.save!
      Download.add_download_to_user_and_model(@user, @product.id)
      @download2 = Download.last

      @download2.remaining.should == MAX_DOWNLOADS
    end

    it "should not add download to user/product if the user has not downloaded at least once" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = Download.new(:user_id => @user.id, :product_id => @product.id)
      @download.save!

      x = Download.add_download_to_user_and_model(@user, @product.id)
      x.should == nil
    end
  end

  describe "update_all_users_who_have_downloaded_at_least_once" do
    it "should update all users who have downloaded at least once" do
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user, :email => 'blah@blah.blah')
      @download1 = FactoryGirl.create(:download, :user_id => @user.id)
      @download2 = FactoryGirl.create(:download, :user_id => @user2.id)
      @product = FactoryGirl.create(:product)
      Download.update_all_users_who_have_downloaded_at_least_once(@product.id)
      @downloads = Download.all
      @downloads.each do |dl|
        dl.remaining.should == 5
      end
    end

    it "should return the users who had their download remaining counts updated" do
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user, :email => 'blah@blah.blah')
      @download1 = FactoryGirl.create(:download, :user_id => @user.id)
      @download2 = FactoryGirl.create(:download, :user_id => @user2.id)
      @product = FactoryGirl.create(:product)
      @affected_downloads = Download.update_all_users_who_have_downloaded_at_least_once(@product.id)
      @affected_downloads.length.should == 2
      @affected_downloads[0].class.should == User
    end
  end

  describe 'self.update_download_counts' do
    context 'with no token passed in' do
      it 'should find the record by user ID and product ID and update count and remaining' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = Download.new(:user_id => @user.id, :product_id => @product.id)
        @download.save!
        Download.should_receive(:find_or_create_by).and_return(@download)
        Download.update_download_counts(@user,@product.id)

        @decremented_download = Download.find(@download.id)

        @decremented_download.remaining.should == MAX_DOWNLOADS-1
        @decremented_download.count.should == 1
      end
    end

    context 'with a token passed in' do
      it 'should find the record by user ID and token and update count and remaining' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = Download.new(:user_id => @user.id, :product_id => @product.id, :download_token => 'token')
        @download.save!
        Download.should_receive(:find_by_user_id_and_download_token).and_return(@download)
        Download.update_download_counts(@user,@product.id, 'token')

        @decremented_download = Download.find(@download.id)

        @decremented_download.remaining.should == MAX_DOWNLOADS-1
        @decremented_download.count.should == 1
      end
    end
  end
end