<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { computed, ref, watch, onMounted, onUnmounted } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

const { updateUISettings } = useUISettings();

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);

const { uiSettings } = useUISettings();
const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const isCopilotPanelOpen = computed(
  () => uiSettings.value.is_copilot_panel_open
);

const toggleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: !isContactSidebarOpen.value,
    is_copilot_panel_open: false,
  });
};

const handleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: true,
    is_copilot_panel_open: false,
  });
};

const handleCopilotSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: true,
  });
};

const keyboardEvents = {
  'Alt+KeyO': {
    action: toggleConversationSidebarToggle,
  },
};
useKeyboardEvents(keyboardEvents);

// HAPPSEA: poll Bridge for AI status so the dot reflects live state
const currentChat = useMapGetter('getSelectedChat');
const aiActive = ref(true);
const bridgeUrl = window.chatwootConfig?.happsea_bridge_url || '';
const bridgeToken = window.chatwootConfig?.happsea_bridge_token || '';

async function fetchAIStatus(convId) {
  if (!bridgeUrl || !convId) return;
  try {
    const headers = bridgeToken ? { Authorization: `Bearer ${bridgeToken}` } : {};
    const res = await fetch(`${bridgeUrl}/api/conversations/${convId}/status`, { headers });
    if (res.ok) {
      const data = await res.json();
      aiActive.value = data.ai_active;
    }
  } catch { /* silent */ }
}

let pollTimer = null;
function startPolling(convId) {
  if (pollTimer) clearInterval(pollTimer);
  aiActive.value = true;
  fetchAIStatus(convId);
  pollTimer = setInterval(() => fetchAIStatus(convId), 8000);
}

watch(() => currentChat.value?.id, id => { if (id) startPolling(id); }, { immediate: true });
onMounted(() => { if (currentChat.value?.id) startPolling(currentChat.value.id); });
onUnmounted(() => { if (pollTimer) clearInterval(pollTimer); });
</script>

<template>
  <ButtonGroup
    class="flex flex-col justify-center items-center absolute top-36 xl:top-24 ltr:right-2 rtl:left-2 bg-n-solid-2/90 backdrop-blur-lg border border-n-weak/50 rounded-full gap-1.5 p-1.5 shadow-sm transition-shadow duration-200 hover:shadow"
  >
    <!-- Contact info button — with AI status dot overlay -->
    <div class="relative">
      <Button
        v-tooltip.top="$t('CONVERSATION.SIDEBAR.CONTACT')"
        ghost
        slate
        sm
        class="!rounded-full transition-all duration-[250ms] ease-out active:!scale-95 active:!brightness-105 active:duration-75"
        :class="{
          'bg-n-alpha-2 active:shadow-sm': isContactSidebarOpen,
        }"
        icon="i-ph-user-bold"
        @click="handleConversationSidebarToggle"
      />
      <!-- AI status dot: amber = paused, hidden when active -->
      <span
        v-if="bridgeUrl && !aiActive"
        class="absolute top-0 ltr:right-0 rtl:left-0 size-2 rounded-full bg-n-amber-9 ring-1 ring-n-solid-2 pointer-events-none"
      />
    </div>
    <Button
      v-if="showCopilotTab"
      v-tooltip.bottom="$t('CONVERSATION.SIDEBAR.COPILOT')"
      ghost
      slate
      sm
      class="!rounded-full transition-all duration-[250ms] ease-out active:!scale-95 active:duration-75"
      :class="{
        'bg-n-alpha-2 !text-n-iris-9 active:!brightness-105 active:shadow-sm':
          isCopilotPanelOpen,
      }"
      icon="i-woot-captain"
      @click="handleCopilotSidebarToggle"
    />
  </ButtonGroup>
</template>
