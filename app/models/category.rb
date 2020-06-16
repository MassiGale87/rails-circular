class Category < ApplicationRecord
  has_many :owners, dependent: :destroy
  validates :category_name, uniqueness: true
end
