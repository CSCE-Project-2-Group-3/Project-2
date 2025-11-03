class AddRecurringFieldsToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_column :expenses, :recurring_type, :string
    add_column :expenses, :recurring_interval, :integer
    add_column :expenses, :next_occurrence_at, :datetime
    add_column :expenses, :end_after_occurrences, :integer
    add_column :expenses, :end_after_date, :date
    add_column :expenses, :is_active, :boolean, default: true

    add_index :expenses, :next_occurrence_at
    add_index :expenses, :is_active
  end
end
