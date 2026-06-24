/* global axios */
import ApiClient from '../ApiClient';

class WhatsappChannel extends ApiClient {
  constructor() {
    super('whatsapp', { accountScoped: true });
  }

  createEmbeddedSignup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, params);
  }

  reauthorizeWhatsApp({ inboxId, ...params }) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, {
      ...params,
      inbox_id: inboxId,
    });
  }

  getTemplates(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates`);
  }

  createTemplate(inboxId, payload) {
    return axios.post(
      `${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates`,
      payload
    );
  }

  deleteTemplate(inboxId, name) {
    return axios.delete(
      `${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates/${encodeURIComponent(name)}`
    );
  }
}

export default new WhatsappChannel();
