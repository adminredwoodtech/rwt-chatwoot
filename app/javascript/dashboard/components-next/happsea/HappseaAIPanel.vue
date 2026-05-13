<script setup>
/**
 * HappseaAIPanel — shows AI status for the current conversation and lets
 * agents resume the AI after a human-takeover handoff.
 *
 * Reads bridge connection details from window.chatwootConfig (injected by Rails).
 * Polls the Bridge /api/conversations/:id/status endpoint every 8 s while the
 * panel is mounted, so agents see live state without a page refresh.
 */
import { ref, watch, onMounted, onUnmounted } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

// --- Bridge config (injected by Rails into window.chatwootConfig) -----------
const bridgeUrl = window.chatwootConfig?.happsea_bridge_url || '';
const bridgeToken = window.chatwootConfig?.happsea_bridge_token || '';

// --- State ------------------------------------------------------------------
const aiActive = ref(true);   // optimistic default — avoids flash of "paused"
const loading = ref(false);
const resuming = ref(false);
const error = ref('');

let pollTimer = null;

// --- Helpers ----------------------------------------------------------------
function authHeaders() {
  const h = { 'Content-Type': 'application/json' };
  if (bridgeToken) h['Authorization'] = `Bearer ${bridgeToken}`;
  return h;
}

async function fetchStatus() {
  if (!bridgeUrl || !props.conversationId) return;
  try {
    const res = await fetch(
      `${bridgeUrl}/api/conversations/${props.conversationId}/status`,
      { headers: authHeaders() }
    );
    if (res.ok) {
      const data = await res.json();
      aiActive.value = data.ai_active;
      error.value = '';
    }
  } catch {
    // Silently ignore network errors — don't distract agents
  }
}

async function resumeAI() {
  if (!bridgeUrl || resuming.value) return;
  resuming.value = true;
  error.value = '';
  try {
    const res = await fetch(
      `${bridgeUrl}/api/conversations/${props.conversationId}/resume`,
      { method: 'POST', headers: authHeaders() }
    );
    if (res.ok) {
      aiActive.value = true;
    } else {
      error.value = 'No se pudo reanudar la IA.';
    }
  } catch {
    error.value = 'Error de conexión con el puente IA.';
  } finally {
    resuming.value = false;
  }
}

// --- Lifecycle --------------------------------------------------------------
function startPolling() {
  fetchStatus();
  pollTimer = setInterval(fetchStatus, 8000);
}

function stopPolling() {
  if (pollTimer) clearInterval(pollTimer);
}

onMounted(startPolling);
onUnmounted(stopPolling);

// Re-fetch immediately when the conversation changes
watch(() => props.conversationId, () => {
  aiActive.value = true; // reset while loading
  fetchStatus();
});
</script>

<template>
  <!-- Only render if the bridge is configured -->
  <div v-if="bridgeUrl" class="px-3 py-2.5 border-t border-n-weak">
    <!-- AI active state — subtle, minimal -->
    <div v-if="aiActive" class="flex items-center gap-2 text-xs text-n-slate-10">
      <span class="size-1.5 rounded-full bg-n-teal-9 flex-shrink-0" />
      IA activa
    </div>

    <!-- AI paused state — prominent, actionable -->
    <div v-else class="space-y-2">
      <div class="flex items-center gap-2 text-xs font-medium text-n-amber-11 dark:text-n-amber-9">
        <span class="size-1.5 rounded-full bg-n-amber-9 flex-shrink-0" />
        IA pausada — agente humano activo
      </div>
      <Button
        sm
        :loading="resuming"
        :disabled="resuming"
        icon="i-ph-robot"
        label="Reanudar IA"
        class="w-full justify-center !text-n-teal-9 !border-n-teal-7 hover:!bg-n-teal-3"
        variant="outline"
        color="slate"
        @click="resumeAI"
      />
      <p v-if="error" class="text-xs text-n-red-9">{{ error }}</p>
    </div>
  </div>
</template>
