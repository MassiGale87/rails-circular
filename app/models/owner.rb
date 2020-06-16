class Owner < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :owner_offers, dependent: :destroy
  has_many :order_items, through: :owner_offers
  validates :name, :description, :address, :category_id, :photo, presence: true
  validates :instagram, :name, uniqueness: true
  validates :facebook, :name, uniqueness: true
  has_one_attached :photo

   def highest_offer
    owner_offer = self.owner_offers
    sorted = owner_offer.sort_by { |k| k["discount"] }.last
  end
end
