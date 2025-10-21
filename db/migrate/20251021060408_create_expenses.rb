class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :merchant
      t.decimal :amount, precision: 12, scale: 2
      t.string :currency, default: "USD"
      t.date :happened_on
      t.references :category, foreign_key: true
      t.text :notes
      t.timestamps
    end
  end
end
