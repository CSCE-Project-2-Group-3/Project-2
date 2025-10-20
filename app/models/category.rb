class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  before_save { self.name = name.strip.titleize }
end
