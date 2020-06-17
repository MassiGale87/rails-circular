class OwnerOffersController < ApplicationController
  before_action :set_order, only: [:add_to_bag, :remove_from_bag, :increase_to_bag]
  # this method is the same as view_user_history or view_user_orders mentioned in trello
  before_action :set_owner, only: [:new, :create]

  def index
    @owner_offers = policy_scope(OwnerOffer)
  end

  def new
    o = OwnerOffer.new
    o.owner_id = params[:owner_id] # attr_accessor of OwnerOffer Model
    @owner_offer = b
    authorize @owner_offer
    # @owner = Owner.find(params[:owner_offer_id])
    # @owner_offer = OwnerOffer.where("owner_offer_id = ?", @owner_offer.id)
  end

  def create
    @owner_offer = OwnerOffer.new(owner_offer_params)
    @owner_offer.owner_id = params[:owner_id]
    @owner_offer.offer_amount = owner_offer_params[:offer_amount].to_i
    @owner_offer.price_cents = (owner_offer_params[:offer_amount].to_f) * (1 - (owner_offer_params[:discount].to_f / 100))

    authorize @owner_offer
    if @owner_offer.save
      redirect_to new_owner_owner_offer_path
    else
      flash.now[:error] = "Offer amount must be unique"
      render :new
    end
  end

  def show; end

  def edit
    @owner_offer = OwnerOffer.find(params[:id])
    authorize @owner_offer
  end

  def update
    @owner_offer = OwnerOffer.find(params[:id])
    authorize @owner_offer
    if @business_offer.update(owner_offer_params)
      flash[:alert] = "Bravo!"
      redirect_to owner_path(@owner_offer.owner_id)
    else
      flash[:alert] = "Can't update owner offer, please try again"
      render :edit
    end
  end

  def destroy; end

  def add_to_bag
    # Route to this method: /owners/:owner_id/business_offers/:id
    authorize OwnerOffer
    @order.add_item_quantity(params[:id])
    redirect_to update_total_amount_cents_path(params[:owner_id])
  end

  def remove_from_bag
    # Route to this method: /owners/:owner_id/owner_offers/:id
    authorize OwnerOffer
    @order.decrease_item_quantity(params[:id])
    redirect_to update_total_amount_cents_checkout_path(params[:owner_id])
  end

  def increase_to_bag
    # Route to this method: /owners/:owner_id/owner_offers/:id
    authorize OwnerOffer
    @order.add_item_quantity(params[:id])
    redirect_to update_total_amount_cents_checkout_path(params[:owner_id])
  end

  private

  def set_owner
    @owner = Owner.find(params[:owner_id])
  end

  def owner_offer_params
    params.require(:owner_offer).permit(:offer_amount, :discount)
  end
end
