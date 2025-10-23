module ExpensesHelper
  def participant_summary(expense)
    participants = expense.participants.to_a

    return "Just you" if participants.blank? || (participants.size == 1 && participants.first.id == expense.user_id)

    per_person = calculate_per_person_share(expense, participants.count)
    names = participants.map { |user| display_user_name(user) }.join(", ")
    "#{per_person}: #{names}"
  end

  def display_user_name(user)
    user.full_name.presence || user.email
  end

  private

  def calculate_per_person_share(expense, count)
    amount = expense.amount.to_f
    return number_to_currency(amount) if count.zero?

    number_to_currency(amount / count)
  end
end
