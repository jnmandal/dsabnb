class HostingsController < ApplicationController
  before_action :find_hosting, only: [:edit, :update, :destroy]
  before_action :ensure_current_user_is_host, only: [:edit, :update, :destroy]
  before_action :set_s3_direct_post, only: [:new, :edit, :create, :update]

  def new
    @hosting ||= Hosting.new(host_id: params[:user_id], start_date: nil, end_date: nil)
  end

  def create
    @hosting = Hosting.new(hosting_params)
    @hosting.host_id = current_user.id

    @images = image_params[:images].map { |i| Image.find_or_create_by(url: i[:url]) }
    @hosting.images << @images

    if @hosting.save
      redirect_to user_url(current_user),
        notice: "Hosting created! We will email you when a nearby traveler would like to stay with you."
    else
      flash.now[:errors] = @hosting.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @images = image_params[:images].map { |i| Image.find_or_create_by(url: i[:url]) }
    @hosting.images = @images

    if @hosting.update(hosting_params)
      redirect_to user_url(current_user),
        notice: "Hosting updated! We will email you when a nearby traveler would like to stay with you."
    else
      flash.now[:errors] = @hosting.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def destroy
    if @hosting.destroy
      redirect_to user_url(current_user), notice: "Hosting canceled"
    else
      flash.now[:errors] = @hosting.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_s3_direct_post
    @s3_direct_post = S3_BUCKET.presigned_post(
      key: "uploads/#{SecureRandom.uuid}/${filename}",
      success_action_status: '201', acl: 'public-read'
    )
  end

  def hosting_params
    params
      .require(:hosting)
      .permit(:zipcode, :max_guests, :comment, :accomodation_type, :start_date, :end_date)
  end

  def image_params
    params.permit(images: [:url])
  end

  def find_hosting
    @hosting = Hosting.find_by_id(params[:id])
    if @hosting.nil?
      flash[:notice] = "Oops! That hosting has been canceled."
      redirect_to user_url(current_user)
    end
  end

  def ensure_current_user_is_host
    redirect_to user_url(current_user) unless @hosting.host_id == current_user.id
  end
end
