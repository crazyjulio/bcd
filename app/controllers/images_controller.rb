class ImagesController < ApplicationController
  before_filter :authenticate_radmin!
  before_filter :get_products
  skip_before_filter :find_cart
  skip_before_filter :get_categories
  skip_before_filter :set_users_referrer_code
  skip_before_filter :set_locale
  layout proc{ |controller| controller.request.xhr? ? false : "admin" }

  # GET /images
  def index
    @images = Image.order("product_id").page(params[:page]).per(20)
  end

  # GET /images/1
  def show
    @image = Image.find(params[:id])
  end

  # GET /images/new
  def new
    if params[:product_id]
      @image = Image.new(:product_id => params[:product_id])
    else
      @image = Image.new
    end
  end

  # GET /images/1/edit
  def edit
    @image = Image.find(params[:id])
  end

  # POST /images
  def create
    @image = Image.new(params[:image])
    if @image.save
      redirect_to(@image, :notice => 'Image was successfully created.')
    else
      flash[:alert] = "Image was NOT created"
      render "new"
    end
  end

  # PUT /images/1
  def update
    @image = Image.find(params[:id])
    if @image.update_attributes(params[:image])
      redirect_to(@image, :notice => 'Image was successfully updated.')
    else
      flash[:alert] = "Image was NOT updated"
      render "edit"
    end
  end

  # DELETE /images/1
  def destroy
    @image = Image.find(params[:id])
    @image.destroy
    redirect_to(images_url)
  end

  private

  def get_products
    products = Product.all.order("name")
    @products = []
    products.each { |product| @products << [product.name, product.id] }
  end
end
