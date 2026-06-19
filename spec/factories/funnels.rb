# frozen_string_literal: true

FactoryBot.define do
  factory :funnel do
    account
    sequence(:name) { |n| "Funnel_#{n}" }
    stages do
      [
        { 'id' => 'todo', 'name' => 'To Do', 'color' => '#64748b' },
        { 'id' => 'doing', 'name' => 'Doing', 'color' => '#3b82f6' },
        { 'id' => 'done', 'name' => 'Done', 'color' => '#22c55e' }
      ]
    end
  end
end
