class Receipt < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :expenses, dependent: :nullify

  validates :status, presence: true
end
