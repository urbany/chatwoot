/* global axios */

import ApiClient from 'dashboard/api/ApiClient';

class KanbanItemsAPI extends ApiClient {
  constructor() {
    super('kanban_items', { accountScoped: true });
  }

  list(funnelId, stage = null) {
    const params = stage ? { stage } : {};
    return axios.get(`${this.baseUrl()}/funnels/${funnelId}/kanban_items`, {
      params,
    });
  }

  move(id, funnelStage, position) {
    return axios.patch(`${this.url}/${id}/move`, {
      funnel_stage: funnelStage,
      position,
    });
  }

  reorder(id, position) {
    return axios.patch(`${this.url}/${id}/reorder`, { position });
  }
}

export default new KanbanItemsAPI();
