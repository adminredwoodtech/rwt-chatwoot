<script setup>
/**
 * HappseaAIButton — always-visible toggle in the conversation header.
 * Shows "Pausar IA" when the AI is active, "Reanudar IA" when paused.
 */
import { ref, watch, onMounted, onUnmounted } from 'vue';
import { useStore } from 'vuex';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const bridgeUrl = window.chatwootConfig?.happsea_bridge_url || '';
const bridgeToken = window.chatwootConfig?.happsea_bridge_token || '';

function getCurrentAgentId() {
  try {
    return store.getters['auth/getCurrentUser']?.id || null;
  } catch {
    return null;
  }
}

const aiActive = ref(true);
const loading = ref(false);

function authHeaders() {
  const h = { 'Content-Type': 'application/json' };
  if (bridgeToken) h['Authorization'] = `Bearer ${bridgeToken}`;
  return h;
}

async function fetchStatus(convId) {
  if (!bridgeUrl || !convId) return;
  try {
    const res = await fetch(
      `${bridgeUrl}/api/conversations/${convId}/status`,
      { headers: authHeaders() }
    );
    if (res.ok) {
      const data = await res.json();
      aiActive.value = data.ai_active;
    }
  } catch { /* silent */ }
}

async function toggle() {
  if (!bridgeUrl || loading.value) return;
  loading.value = true;
  const action = aiActive.value ? 'pause' : 'resume';
  try {
    const body = {};
    // When pausing, include the current agent's ID so the Bridge can
    // auto-assign the conversation to the agent taking over.
    if (action === 'pause') {
      const agentId = getCurrentAgentId();
      if (agentId) body.agent_id = agentId;
    }
    const res = await fetch(
      `${bridgeUrl}/api/conversations/${props.conversationId}/${action}`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify(body),
      }
    );
    if (res.ok) aiActive.value = !aiActive.value;
  } catch { /* silent */ } finally {
    loading.value = false;
  }
}

let pollTimer = null;

function startPolling(convId) {
  if (pollTimer) clearInterval(pollTimer);
  aiActive.value = true;
  fetchStatus(convId);
  pollTimer = setInterval(() => fetchStatus(convId), 8000);
}

watch(() => props.conversationId, id => { if (id) startPolling(id); });
onMounted(() => { if (props.conversationId) startPolling(props.conversationId); });
onUnmounted(() => { if (pollTimer) clearInterval(pollTimer); });
</script>

<template>
  <button
    v-if="bridgeUrl"
    :disabled="loading"
    class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium border transition-all duration-150 disabled:opacity-60 disabled:cursor-not-allowed"
    :class="aiActive
      ? 'bg-n-alpha-1 border-n-weak text-n-slate-10 hover:bg-n-alpha-2 hover:text-n-slate-11'
      : 'bg-n-amber-3 border-n-amber-7 text-n-amber-11 hover:bg-n-amber-4 dark:bg-n-amber-9/20 dark:border-n-amber-7 dark:text-n-amber-9'"
    @click="toggle"
  >
    <span
      class="size-1.5 rounded-full flex-shrink-0 transition-colors"
      :class="aiActive ? 'bg-n-teal-9' : 'bg-n-amber-9'"
    />
    <span>{{ loading ? '…' : (aiActive ? 'Pausar IA' : 'Reanudar IA') }}</span>
  </button>
</template>
