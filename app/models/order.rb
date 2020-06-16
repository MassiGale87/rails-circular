class Order < ApplicationRecord
  # belongs_to :order_item
  has_many :order_items, dependent: :destroy
  has_many :owner_offers, through: :order_items
  belongs_to :user
  monetize :total_amount_cents
  before_save :set_expiration_date

  def add_item_quantity(owner_offer_id)
      @order_item = OrderItem.where("order_id = ? AND owner_offer_id = ?", self.id, owner_offer_id.to_i).first

      if !@order_item.nil?
        @order_item.quantity += 1
        @order_item.save
      else
        @order_item =  OrderItem.new(owner_offer_id: owner_offer_id,
          quantity: 1,
          order_id: self.id)
        @order_item.save
      end

      @order_item
  end

  def decrease_item_quantity(owner_offer_id)
      @order_item = OrderItem.where("order_id = ? AND owner_offer_id = ?", self.id, owner_offer_id.to_i).first
      if !@order_item.nil?
        if @order_item.quantity == 0
          @order_item.quantity = 0
        else
          @order_item.quantity -= 1
        end
        @order_item.save
      end
      @order_item
  end


  # def total_calculator
  #   @order_items = self.order_items
  #   updated_total_amount_cents = 0
  #   # raise
  #   @order_items.each do |order_item|
  #     owner_offer = OwnerOffer.find(order_item.owner_offer_id)
  #     # This needs to be total of discounted amount:
  #     updated_total_amount_cents += owner_offer.price_cents * order_item.quantity
  #   end
  #   first_name = User.find(self.user_id).first_name
  #   last_name = User.find(self.user_id).last_name
  #   if total_amount_cents == 0
  #         self.update( total_amount_cents: updated_total_amount_cents, order_date: Date.new)
  #   else
  #   session = Stripe::Checkout::Session.create(
  #     payment_method_types: ['card'],
  #     line_items: [{
  #       name: "#{first_name}, #{last_name}",
  #       amount: self.total_amount_cents,
  #       currency: 'eur',
  #       quantity: 1
  #     }],
  #     success_url: "/orders?payment=success",
  #     cancel_url: "/orders?payment=fail"
  #   )
  #   self.update(checkout_session_id: session.id, total_amount_cents: updated_total_amount_cents, order_date: Date.new)
  # end
  # end

private

  def set_expiration_date
    puts self
    self.exp_date = Date.today + 10
    puts self
  end

end
