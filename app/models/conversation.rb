class Conversation < ApplicationRecord
  # Conversations are always between two users (user_a and user_b)
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"

  has_many :messages, dependent: :destroy

  validates :user_a_id, presence: true
  validates :user_b_id, presence: true
  validate :different_users

  scope :between, ->(user1, user2) {
    a, b = order_pair(user1.id, user2.id)
    where(user_a_id: a, user_b_id: b)
  }

  # Ensures consistent conversation lookup regardless of parameter order
  def self.find_or_create_between(user1, user2)
    return nil if user1.blank? || user2.blank? || user1.id == user2.id
    a, b = order_pair(user1.id, user2.id)
    conversation = find_by(user_a_id: a, user_b_id: b)
    return conversation if conversation.present?

    create!(user_a_id: a, user_b_id: b)
  end

  def participants
    User.where(id: [ user_a_id, user_b_id ])
  end

  def other_user(user)
    return user_b if user.id == user_a_id
    return user_a if user.id == user_b_id
    nil
  end

  private

  def different_users
    errors.add(:base, "Conversation must be between two different users") if user_a_id == user_b_id
  end

  # Normalizes user IDs to ensure consistent conversation lookup
  def self.order_pair(id1, id2)
    ids = [ id1.to_i, id2.to_i ].sort
    return ids[0], ids[1]
  end

  def order_pair(id1, id2)
    self.class.order_pair(id1, id2)
  end
end
