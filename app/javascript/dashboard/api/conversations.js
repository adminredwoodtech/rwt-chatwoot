/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  getAgentReview(conversationID) {
    return axios.get(`${this.url}/${conversationID}/agent_reviews`);
  }

  submitAgentReview(conversationID, note) {
    return axios.post(`${this.url}/${conversationID}/agent_reviews`, { note });
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }
}

export default new ConversationApi();
