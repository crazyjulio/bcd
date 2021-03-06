class DownloadsController < ApplicationController
  before_filter :authenticate_user!, :only => [:download, :download_parts_list]
  before_filter :valid_guest, :only => [:guest_download_parts_list]


  def download_parts_list
    @parts_list = PartsList.find(params[:parts_list_id])
    if @parts_list
      @product = Product.find(@parts_list.product_id)
      #Check users completed orders and see if they're entitled to the parts lists
      @orders = current_user.completed_orders
      products = []
      @orders.each do |order|
        order.line_items.each do |li|
          products << li.product_id
        end
      end

      #Now, get all freebie product IDs
      products << Product.find_all_by_price('free').pluck(:id)
      products.flatten!

      unless products.include?(@parts_list.product_id)
        return redirect_cheater_to_product_page
      end

      deliver_download(@parts_list.name.path)
    else
      logger.error("Someone tried to access a nonexistent parts list with an ID of #{params[:parts_list_id]}")
    end
  end

  def guest_download_parts_list
    @parts_list = PartsList.find(params[:parts_list_id])
    if @parts_list
      @product = Product.find(@parts_list.product_id)
      #Check users completed orders and see if they're entitled to the parts lists
      #Make sure I test this via unit tests  and actually clicking around in the browser
      @order = Order.find(params[:order_id])
      @user = @order.user
      products = []
      @order.line_items.each do |li|
        products << li.product_id
      end
      unless @user.guest?
        @freebies = Product.find_all_by_price('free')
        @freebies.each do |product|
          products << product.id
        end
      end

      if @product.is_free? && @user.guest? #Guest User is trying to download parts list for free instructions
        flash[:alert] = "Sorry, free instructions are only available to non-guests."
        return redirect_to '/'
      end

      unless products.include?(@parts_list.product_id)
        return redirect_cheater_to_product_page
      end

      deliver_download(@parts_list.name.path)
    else
      logger.error("Someone tried to access a nonexistent parts list with an ID of #{params[:parts_list_id]}")
    end
  end

  def download
    @product = Product.find_by_base_product_code(params[:product_code])
    @downloads_remaining = get_users_downloads_remaining(@product.id)
    if @downloads_remaining == 0
      redirect_to :back, :notice => "You have already reached your maximum allowed number of downloads for #{@product.base_product_code} #{@product.name}.", :only_path => true
    elsif @downloads_remaining.blank? && !@product.is_free?
      flash[:alert] = "Nice try. You can buy instructions for this model on this page, and then you can download them."
      redirect_to :controller => :store, :action => :product_details, :product_code => @product.product_code, :product_name => @product.name.to_snake_case
    else
      deliver_download(@product.pdf.path)
    end
    increment_download_count
  end

  def guest_downloads
    transaction_id = params[:tx_id]
    request_id = params[:conf_id]
    if transaction_id.blank? || request_id.blank?
      return redirect_to download_link_error_path
    end
    @order = Order.where(["transaction_id=? and request_id=?",transaction_id,request_id]).first
    if @order.blank?
      return redirect_to download_link_error_path
    end
    session[:guest_has_arrived_for_downloads] = true
    @download_links = @order.get_download_links
  end

  def guest_download
    #Look up download record by token and user id, which I get from a ID passed in, which is the users guid
    #if download record is found, increment count, decrement remaining, and redirect to an S3 url for the PDF
    user_guid, download_token = params[:id], params[:token]
    return redirect_to download_error_path if user_guid.blank? || download_token.blank?

    user = User.where(["guid = ?", user_guid]).first
    return redirect_to download_error_path if user.blank?

    @download = Download.where(["user_id = ? and download_token = ?",user.id,download_token]).first
    if @download.blank?
      return redirect_to download_error_path
    else
      @downloads_remaining = @download.remaining
      if @downloads_remaining == 0
        return redirect_to '/', :notice => "You have already reached your maximum allowed number of downloads for these instructions."
      else
        @product = Product.find(@download.product_id)
        deliver_download(@product.pdf.path)
      end
    end
    increment_download_count(user)
  end

  private

  def deliver_download(file)
    if Rails.env != "development"
      download_from_amazon(file)
    else
      #:nocov:
      download_from_local(file) #In case I need to test downloads locally
      #:nocov:
    end
  end

  def redirect_cheater_to_product_page
    flash[:alert] = "Nice try. You can buy instructions for this model on this page, and then you can download the parts lists."
    redirect_to :controller => :store, :action => :product_details, :product_code => @product.product_code, :product_name => @product.name.to_snake_case
  end

  def download_from_amazon(file)
    link = Amazon::Storage.authenticated_url(file)
    redirect_to link
  end

  #:nocov:
  def download_from_local(file)
    filename = file.match(/\w+\.\w+/).to_s
    send_file(file, :type => 'application/pdf', :filename => filename, :disposition => "attachment")
  end
  #:nocov:

  def valid_guest
    if session[:guest_has_arrived_for_downloads].blank?
      redirect_to '/', :notice => 'Sorry, you need to have come to the site legitimately to be able to download parts lists.'
    end
  end

  def increment_download_count(user=nil)
    user ||= current_user
    if @download
      @product ||= Product.find(@download.product_id)
      @token = @download.download_token #if this ends up being nil, that's fine, nil gets passed to update_download_counts
    end
    #If the admin is posing as the user, downloads by the admin shouldn't count against the users download count.
    unless current_radmin || @downloads_remaining == 0
      Download.update_download_counts(user,@product.id,@token)
    end
  end

  def get_users_downloads_remaining(product_id)
    current_user
    if current_user.owns_product?(product_id)
      @download = Download.find_by_user_id_and_product_id(current_user,product_id)
      @download.blank? ? MAX_DOWNLOADS : @download.remaining
    else
      nil
    end
  end
end
