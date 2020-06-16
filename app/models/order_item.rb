class OrderItem < ApplicationRecord
  belongs_to :owner_offer  # .owner_offer
  belongs_to :order           # .oder
end
