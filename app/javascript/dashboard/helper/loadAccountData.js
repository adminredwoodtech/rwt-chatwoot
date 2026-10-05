// HAPPSEA: account data the sidebar normally loads on mount. When the Hub
// embeds the dashboard the sidebar is not rendered, so the dashboard loads it
// instead. Without inboxes the reply box cannot tell the channel type and hides
// attachments and audio; labels, teams and attributes would also be empty.
export const loadAccountData = store => {
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('attributes/get');
  store.dispatch('customViews/get', 'conversation');
  store.dispatch('customViews/get', 'contact');
};
