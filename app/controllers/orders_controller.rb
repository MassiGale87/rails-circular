class OrdersController < ApplicationController
  before_action :set_order, only: [:total_calculator, :update_total_amount_cents, :update_total_amount_cents_checkout, :update]
  before_action :total_calculator, only: [:update_total_amount_cents, :update_total_amount_cents_checkout]

def index
    @orders_index_pundit = policy_scope(Order)
    if params[:payment] == "success"
    current_user.orders.last.update(order_date: Date.today, exp_date: Date.today + 30, state: 'pending', paid: true, owner_paid: true)
    elsif params[:payment] == "fail"
    current_user.orders.last.update(order_date: Date.today, state: 'failed', paid: false, owner_paid: false)
    end
    if current_user.owner
      @orders = []
      business = current_user.businesses.last
      @order_items = business.order_items
      if params[:offer].present?
        # GET OWNER ORDERS WHEN THERES A FILTER
        order_items = @order_items.where(owner_offer: OwnerOffer.find(params[:offer].to_i))
        @orders = order_items.map { |order_item| order_item.order }.uniq
      elsif params[:order_query].present?
        @order_items.each do |order_item|
          sql_query = "confirmation_no ILIKE :order_query OR CAST(total_amount_cents AS TEXT) ILIKE :order_query OR CAST(order_date AS TEXT) ILIKE :order_query OR CAST(exp_date AS TEXT) ILIKE :order_query AND state = 'pending' AND id = #{order_item.order_id} AND paid = true"
          all_orders = @orders_index_pundit.where(sql_query, order_query: "%#{params[:order_query]}%")
          sql_query = "confirmation_no ILIKE :order_query OR CAST(total_amount_cents AS TEXT) ILIKE :order_query OR CAST(order_date AS TEXT) ILIKE :order_query OR CAST(exp_date AS TEXT) ILIKE :order_query AND  state = 'paid' AND id = #{order_item.order_id} AND paid = true"
          all_orders = @orders_index_pundit.where(sql_query, order_query: "%#{params[:order_query]}%")
          all_orders.each do |order|
            @orders.push(order)
          end
        end
      else
        # GET OWNER ORDERS
        @orders = @order_items.map { |order_item| order_item.order }.uniq
      end
      return
    else
      # @orders = Order.where("user_id = ?", current_user.id)
      if params[:order_query].present?
        sql_query = "confirmation_no ILIKE :order_query OR CAST(total_amount_cents AS TEXT)  ILIKE :order_query OR CAST(exp_date AS TEXT) ILIKE :order_query OR CAST(order_date AS TEXT) ILIKE :order_query AND state = 'pending' AND user_id = #{current_user.id} AND paid = true"
        @orders = @orders_index_pundit.where(sql_query, order_query: "%#{params[:order_query]}%")
        sql_query = "confirmation_no ILIKE :order_query OR CAST(total_amount_cents AS TEXT)  ILIKE :order_query OR CAST(exp_date AS TEXT) ILIKE :order_query OR CAST(order_date AS TEXT) ILIKE :order_query AND state = 'paid' AND user_id = #{current_user.id} AND paid = true"
        @orders = @orders_index_pundit.where(sql_query, order_query: "%#{params[:order_query]}%")
        # raise
      else
        @orders = @orders_index_pundit.where("user_id = ?", current_user.id)
      end
    end
  end

  def new
    @order = Order.new
    authorize @order
  end

  def create
    authorize @order
  end


  def show_cart
# If user has no order at all, send false to show empty bag
    if current_user.orders.last.nil?
      @order = false
    else
      @order = current_user.orders.last
        @orders = current_user.orders
        show_alert = @orders.any? do |ord|
          (Date.today + 10) > ord.exp_date if ord.exp_date
        end
        if show_alert
          flash[:alert] = "One or more orders are going to expire within 10 days"
        end
# If user's order is already paid, send false to show empty bag
        if @order.paid
          @order = false
        end
        @order
    end
    authorize Order.new
  end


  def edit
  end


  def update
    authorize @order
    @order.update(gift: true)
    @order.update(order_params)
    render :show_cart
  end


  def destroy; end

  def update_total_amount_cents
    authorize @order
    # @order.total_calculator
    redirect_to owner_path(params[:owner_id]), notice: "Your order is added to the bag"
  end

  def update_total_amount_cents_checkout
    authorize @order
    # @order.total_calculator
    redirect_to show_cart_path, notice: "Shopping bag is updated!"
  end

  def total_calculator
    @order_items = OrderItem.where("order_id = ?", @order.id)
    updated_total_amount_cents = 0
    @order_items.each do |order_item|
      owner_offer = OwnerOffer.find(order_item.owner_offer_id)
      # This needs to be total of dicscounted amount:
      updated_total_amount_cents += owner_offer.price_cents * order_item.quantity
    end
    @order.update(total_amount_cents: updated_total_amount_cents , order_date: Date.today)

    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{
        name: "#{current_user.first_name} #{current_user.last_name}",
        amount: updated_total_amount_cents * 100,
        currency: 'eur',
        quantity: 1
      }],
      success_url:"#{orders_url}?payment=success",
      cancel_url: "#{orders_url}?payment=fail"
    )

    @order.update(checkout_session_id: session.id)
  end

  def order_params
    params.require(:order).permit(:gift, :gift_email, :gift_message)
  end
end
