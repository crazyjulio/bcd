require 'spec_helper'

describe Download do
  before do
    @product_type = FactoryGirl.create(:product_type)
    @category = FactoryGirl.create(:category)
    @subcategory = FactoryGirl.create(:subcategory)
  end

  describe "add_download_to_user_and_model" do
    it "should add download to user/product if the user has downloaded at least once" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = Download.new(:user_id => @user.id, :product_id => @product.id, :remaining => MAX_DOWNLOADS-1)
      @download.save!
      Download.add_download_to_user_and_model(@user, @product.id)
      @download2 = Download.last

      expect(@download2.remaining).to eq(MAX_DOWNLOADS)
    end

    it "should not add download to user/product if the user has not downloaded at least once" do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = Download.new(:user_id => @user.id, :product_id => @product.id)
      @download.save!

      download = Download.add_download_to_user_and_model(@user, @product.id)
      expect(download).to be_nil
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
        expect(dl.remaining).to eq(5)
      end
    end

    it "should return the users who had their download remaining counts updated" do
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user, :email => 'blah@blah.blah')
      @download1 = FactoryGirl.create(:download, :user_id => @user.id)
      @download2 = FactoryGirl.create(:download, :user_id => @user2.id)
      @product = FactoryGirl.create(:product)
      @affected_downloads = Download.update_all_users_who_have_downloaded_at_least_once(@product.id)
      expect(@affected_downloads.size).to eq(2)
      expect(@affected_downloads[0].class).to eq(User)
    end
  end

  describe 'self.update_download_counts' do
    context 'with no token passed in' do
      it 'should find the record by user ID and product ID and update count and remaining' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = Download.new(:user_id => @user.id, :product_id => @product.id)
        @download.save!
        expect(Download).to receive(:find_or_create_by).and_return(@download)
        Download.update_download_counts(@user,@product.id)

        @decremented_download = Download.find(@download.id)

        expect(@decremented_download.remaining).to eq(MAX_DOWNLOADS-1)
        expect(@decremented_download.count).to eq(1)
      end
    end

    context 'with a token passed in' do
      it 'should find the record by user ID and token and update count and remaining' do
        @user = FactoryGirl.create(:user)
        @product = FactoryGirl.create(:product)
        @download = Download.new(:user_id => @user.id, :product_id => @product.id, :download_token => 'token')
        @download.save!
        expect(Download).to receive(:find_by_user_id_and_download_token).and_return(@download)
        Download.update_download_counts(@user,@product.id, 'token')

        @decremented_download = Download.find(@download.id)

        expect(@decremented_download.remaining).to eq(MAX_DOWNLOADS-1)
        expect(@decremented_download.count).to eq(1)
      end
    end
  end

  describe 'restock' do
    it 'should add MAX_DOWNLOADS to @remaining' do
      @user = FactoryGirl.create(:user)
      @product = FactoryGirl.create(:product)
      @download = FactoryGirl.create(:download, remaining: 1)
      @download.restock

      expect(@download.remaining).to eq MAX_DOWNLOADS+1
    end
  end
end
