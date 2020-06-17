class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, except: [:home, :about]

  include Pundit

  # Pundit: white-list approach.
  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  # Uncomment when you *really understand* Pundit!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    # devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password])
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:first_name, :last_name, :email, :password, :password_confirmation, :owner)
    end

    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  def after_sign_in_path_for(resource)
    # return the path based on resource
    if resource.owner
      @owner = Owner.find_by(user_id: resource.id)
      if resource.owners.size > 0
        return owner_path(@owner)
      else
        return new_owner_path
      end
    else
      return root_path
    end
  end

  private

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def user_not_authorized
    if user_signed_in?
      if current_user.owner
        flash[:alert] = "Please login as user to perform this action."
      else
        flash[:alert] = "Only businesses are authorized to perform this action."
      end
    else
      flash[:alert] = "Please create an account to perform this action."
    end
    redirect_to(request.referrer || root_path)
  end

  def set_order
    if current_user.orders.nil? || current_user.orders.last.nil? || current_user.orders.last.paid
      @order = Order.create(paid: false, user_id: current_user.id, owner_paid: false, gift: false)
      @order.update(confirmation_no: "CH#{@order.id}Ke120#{@order.id}")
      # cookies.delete(:order_id)
      # cookies[:order_id] = @order.id
    else
      @order = current_user.orders.last
      # cookies.delete(:order_id)
      # cookies[:order_id] = @order.id
    end
  end
end
