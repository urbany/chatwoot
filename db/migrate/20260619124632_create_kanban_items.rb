class CreateKanbanItems < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_items do |t|
      t.references :account, null: false, foreign_key: true
      t.references :funnel, null: false, foreign_key: true
      t.string :funnel_stage, null: false
      t.integer :position, null: false, default: 0
      t.jsonb :item_details, null: false, default: {}
      t.bigint :conversation_display_id
      t.timestamps
    end

    add_index :kanban_items, [:account_id, :funnel_id, :funnel_stage]
    add_index :kanban_items, [:account_id, :conversation_display_id]
  end
end
