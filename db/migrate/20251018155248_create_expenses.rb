class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :category, null: false, foreign_key: true
      t.string :title
      t.text :notes
      t.decimal :amount, precision: 12, scale: 2
      t.date :spent_on

      t.timestamps
    end
  end
end
