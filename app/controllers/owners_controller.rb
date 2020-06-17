class OwnersController < ApplicationController
  before_action :set_owner, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]
  def index
    @owners_index_pundit = policy_scope(Owner)
    if params[:query].present?
            sql_query = " \
        owners.name ILIKE :query \
        OR owners.description ILIKE :query \
        OR owners.address ILIKE :query \
        OR categories.category_name ILIKE :query \
      "
      @owners = @owners_index_pundit.joins(:category).where(sql_query, query: "%#{params[:query]}%")
    elsif params[:category].present?
      @category = Category.find_by(category_name: params[:category])
      @owners = @category ? @owners_index_pundit.where(category: @category) : @owners_index_pundit
    else
      @owners = @owners_index_pundit
    end

    @user = current_user
    if user_signed_in? # given by DEVICE!!
      if !@user.orders.nil?
        @orders = @user.orders
        show_alert = @orders.any? do |ord|
          (Date.today + 10) > ord.exp_date if ord.exp_date
        end
         if show_alert
           flash[:alert] = "One or more orders are going to expire within 10 days"
         end
      end
    end
  end



  def order_history_owners
    authorize Owner
    @orders = Order.where(user: current_user) # It is the same ---> @orders = current_user.orders
    @owners = []
    @orders.each do |order|
      order.order_items.each do |order_item|
        owner = order_item.owner_offer.owner #  OrderItems belongs_to :owner_offer  & OwnerOffers belongs_to :owner
        @owners << owner unless @owners.include?(owner)
      end
    end
  end


  def new
    @owner = Owner.new
    authorize @owner
  end

  def create
    # @category = Category.find(params[:id])
    @owner = Owner.new(business_params)
    @owner.user_id = current_user.id
    authorize @owner
    # @owner.category_id = params[:category_id]
    if @owner.save
      redirect_to new_owner_owner_offer_path(@owner)
    else
      render :new
    end
  end

  def show
    # @owner = Owner.find(params[:id]) # set_owner in private already does this job
    @owners = Owner.all
  end

  def edit
    @owner = Owner.find(params[:id])
  end

  def update
    @owner = Owner.find(params[:id])
    @owner.update(owner_params)

    redirect_to owner_path(@owner)
  end

  def destroy
  end

  def view_history
  end

  def view_orders
    @order = Order.all
  end

  private

  def owner_params
    params.require(:owner).permit(:name, :address, :instagram, :facebook, :photo, :description, :category_id)
  end

  def set_owner
    @owner = Owner.find(params[:id])
    authorize @owner
  end
end
