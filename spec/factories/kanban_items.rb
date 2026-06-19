# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_item do
    account
    funnel
    funnel_stage { 'todo' }
    sequence(:position) { |n| n }
    item_details do
      {
        'title' => 'Test item',
        'description' => 'Test description',
        'priority' => 'medium'
      }
    end
  end
end
