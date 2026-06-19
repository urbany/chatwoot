# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Funnels API', type: :request do
  let!(:account) { create(:account) }
  let!(:funnel) { create(:funnel, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/funnels' do
    it 'returns unauthorized for unauthenticated users' do
      get "/api/v1/accounts/#{account.id}/funnels"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns funnels for agents' do
      get "/api/v1/accounts/#{account.id}/funnels", headers: agent.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to include(funnel.name)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/funnels' do
    let(:valid_params) do
      {
        funnel: {
          name: 'Sales Pipeline',
          stages: [{ id: 'lead', name: 'Lead', color: '#64748b' }]
        }
      }
    end

    it 'returns unauthorized for agents' do
      post "/api/v1/accounts/#{account.id}/funnels",
           headers: agent.create_new_auth_token,
           params: valid_params,
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a funnel for admins' do
      expect do
        post "/api/v1/accounts/#{account.id}/funnels",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json
      end.to change(Funnel, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/funnels/:id' do
    it 'updates the funnel for admins' do
      patch "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}",
            headers: admin.create_new_auth_token,
            params: { funnel: { name: 'Updated' } },
            as: :json

      expect(response).to have_http_status(:success)
      expect(funnel.reload.name).to eq('Updated')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/funnels/:id' do
    it 'destroys the funnel for admins' do
      expect do
        delete "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(Funnel, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end
end
