# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Funnel do
  let(:account) { create(:account) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:kanban_items).dependent(:destroy) }

  describe 'validations' do
    before { create(:funnel, account: account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
    it { is_expected.to validate_presence_of(:stages) }

    it 'validates that stages have ids' do
      funnel = build(:funnel, account: account, stages: [{ 'name' => 'No id' }])
      expect(funnel).not_to be_valid
      expect(funnel.errors[:stages]).to include('stage 1 is missing an id')
    end
  end

  describe '#stage_ids' do
    it 'returns the ids of the stages' do
      funnel = create(:funnel, account: account)
      expect(funnel.stage_ids).to eq(%w[todo doing done])
    end
  end
end
