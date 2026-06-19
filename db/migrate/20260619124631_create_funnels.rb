class CreateFunnels < ActiveRecord::Migration[7.0]
  def change
    create_table :funnels do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.jsonb :stages, null: false, default: []
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :funnels, [:account_id, :name], unique: true
  end
end
