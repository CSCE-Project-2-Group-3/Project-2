class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :expenses, dependent: :destroy

  # Future: has_many :expenses, dependent: :destroy

  before_create :generate_join_code

  validates :name, presence: { message: "Group name can't be blank" }
  validates :join_code, uniqueness: true

  def add_member(user)
    return if users.include?(user)
    users << user
  end

  private

  def generate_join_code
    self.join_code ||= SecureRandom.hex(4).upcase  # Example: “A9F3C1D2”
  end
end
