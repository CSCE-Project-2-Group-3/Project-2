class Expense < ApplicationRecord
  belongs_to :category
  belongs_to :user
  belongs_to :group, optional: true
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_on, presence: true
  validate  :participants_belong_to_group

  before_validation :normalize_participant_ids

  scope :recent, -> { order(spent_on: :desc) }
  scope :for_user, lambda { |user_id|
    id = Array(user_id).first.to_i
    table = arel_table

    if sqlite_adapter?
      patterns = [ "[#{id}]", "[#{id},%", "%,#{id},%", "%,#{id}]" ]
      participant_clause = patterns.map { |pattern| table[:participant_ids].matches(pattern) }
                                   .reduce { |memo, node| memo.or(node) }
      participant_clause ||= table[:participant_ids].matches("[#{id}]")
      where(table[:user_id].eq(id)).or(where(participant_clause))
    else
      where(table[:user_id].eq(id)).or(where("? = ANY(participant_ids)", id))
    end
  }

  def participants
    return User.none if participant_ids.blank?

    User.where(id: participant_ids)
  end

  def participant_ids=(raw_ids)
    cleaned = normalize_ids(raw_ids)
    super(serialize_participant_ids(cleaned))
  end

  def participant_ids
    normalize_ids(deserialize_participant_ids(super()))
  end

  private

  def normalize_participant_ids
    ids = participant_ids
    ids = [ user_id ].compact if ids.blank? && user_id.present?
    self.participant_ids = ids
  end

  def participants_belong_to_group
    ids = participant_ids
    return if ids.blank?

    if group.blank?
      extra_ids = ids - [ user_id ]
      errors.add(:participant_ids, "can only include yourself for personal expenses") if extra_ids.any?
      return
    end

    group_member_ids = group.group_memberships.pluck(:user_id)
    invalid = ids - group_member_ids
    errors.add(:participant_ids, "must be members of the group") if invalid.any?
  end

  def normalize_ids(values)
    Array(values).flatten.filter_map do |value|
      str = value.to_s.strip
      next if str.blank?

      Integer(str, 10)
    rescue ArgumentError
      nil
    end.uniq
  end

  def deserialize_participant_ids(raw)
    case raw
    when String
      raw.present? ? JSON.parse(raw) : []
    when Array
      raw
    when nil
      []
    else
      Array(raw)
    end
  rescue JSON::ParserError
    []
  end

  def serialize_participant_ids(ids)
    sqlite_adapter? ? ids.to_json : ids
  end

  def sqlite_adapter?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end

  def self.sqlite_adapter?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end
end
