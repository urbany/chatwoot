# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanItem do
  let(:account) { create(:account) }
  let(:funnel) { create(:funnel, account: account) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to belong_to(:funnel) }
  it { is_expected.to belong_to(:conversation).optional }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:funnel_stage) }
    it { is_expected.to validate_presence_of(:position) }

    it 'validates that the stage exists in the funnel' do
      item = build(:kanban_item, account: account, funnel: funnel, funnel_stage: 'invalid')
      expect(item).not_to be_valid
      expect(item.errors[:funnel_stage]).to include('is not a valid stage for this funnel')
    end
  end

  describe 'scopes' do
    let!(:item_one) { create(:kanban_item, account: account, funnel: funnel, funnel_stage: 'todo', position: 2) }
    let!(:item_two) { create(:kanban_item, account: account, funnel: funnel, funnel_stage: 'todo', position: 1) }
    let!(:item_three) { create(:kanban_item, account: account, funnel: funnel, funnel_stage: 'doing', position: 1) }

    it 'orders by position and created_at' do
      expect(funnel.kanban_items.ordered).to eq([item_two, item_three, item_one])
    end

    it 'filters by stage' do
      expect(funnel.kanban_items.for_stage('todo')).to contain_exactly(item_one, item_two)
    end
  end
end
