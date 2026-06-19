# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'KanbanItems API', type: :request do
  let!(:account) { create(:account) }
  let!(:funnel) { create(:funnel, account: account) }
  let!(:item) { create(:kanban_item, account: account, funnel: funnel, funnel_stage: 'todo') }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/funnels/:funnel_id/kanban_items' do
    it 'returns items for agents' do
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/kanban_items",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).to include(item.id.to_s)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/kanban_items' do
    let(:valid_params) do
      {
        kanban_item: {
          funnel_id: funnel.id,
          funnel_stage: 'todo',
          position: 1,
          item_details: { title: 'New item' }
        }
      }
    end

    it 'creates an item for agents' do
      expect do
        post "/api/v1/accounts/#{account.id}/kanban_items",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json
      end.to change(KanbanItem, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/kanban_items/:id/move' do
    it 'moves the item to another stage' do
      patch "/api/v1/accounts/#{account.id}/kanban_items/#{item.id}/move",
            headers: agent.create_new_auth_token,
            params: { funnel_stage: 'doing', position: 1 },
            as: :json

      expect(response).to have_http_status(:success)
      expect(item.reload.funnel_stage).to eq('doing')
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/kanban_items/:id/reorder' do
    it 'updates the item position' do
      patch "/api/v1/accounts/#{account.id}/kanban_items/#{item.id}/reorder",
            headers: agent.create_new_auth_token,
            params: { position: 5 },
            as: :json

      expect(response).to have_http_status(:success)
      expect(item.reload.position).to eq(5)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/kanban_items/:id' do
    it 'destroys the item for admins' do
      expect do
        delete "/api/v1/accounts/#{account.id}/kanban_items/#{item.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(KanbanItem, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end
end
