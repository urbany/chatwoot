import ApiClient from 'dashboard/api/ApiClient';

class FunnelsAPI extends ApiClient {
  constructor() {
    super('funnels', { accountScoped: true });
  }
}

export default new FunnelsAPI();
