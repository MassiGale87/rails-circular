class OrderItemsController < ApplicationController
  before_action :set_order, only: [:create, :destroy]

  def index
  end

  def new
  end

  def create
    authorize @order_item
  end

  def show
  end

  def edit
    create
  end

  def update
    authorize @order_item
  end

  def destroy

    @order_item = OrderItem.find(params[:id])
    authorize @order_item
    quantity = @order_item.quantity
    price = @order_item.owner_offer.price_cents
    current_item_amount = quantity * price
    order = Order.find(@order_item.order_id)
    updated_amount = order.total_amount_cents - current_item_amount
    @order_item.destroy
    order.update(total_amount_cents: updated_amount)
    if updated_amount == 0
      updated_amount = 1
    end
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{
        name: "#{current_user.first_name} #{current_user.last_name}",
        # amount: order.total_amount_cents * 100,
        amount: updated_amount * 100,
        currency: 'eur',
        quantity: 1
      }],
      success_url:"#{orders_url}?payment=success",
      cancel_url: "#{orders_url}?payment=fail"
    )
    order.update(checkout_session_id: session.id)
    redirect_to show_cart_path, notice: "Item is deleted!"
  end
end
