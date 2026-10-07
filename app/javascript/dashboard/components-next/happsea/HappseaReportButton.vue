<script setup>
/**
 * HappseaReportButton — "Reportar" next to "Pausar IA" in the conversation header.
 * Flags the conversation for the review agent, with an optional note.
 */
import { computed, ref, watch, onUnmounted } from 'vue';
import ConversationApi from 'dashboard/api/conversations';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  conversationId: { type: Number, required: true },
});

// HappSea's agents work in Spanish; like "Pausar IA", this copy is not translated.
const COPY = {
  button: 'Reportar',
  pending: 'En revisión',
  buttonHint: 'Reportar esta conversación para revisión',
  pendingHint: 'El agente revisor está analizando esta conversación',
  title: 'Reportar conversación',
  description:
    'Esta conversación quedará marcada y el agente revisor analizará cómo respondió la IA. ' +
    'Si quieres, agrega una nota para aclarar qué salió mal.',
  noteLabel: 'Nota (opcional)',
  notePlaceholder: 'Por ejemplo: el agente ignoró el cambio de fecha.',
  confirm: 'Reportar',
  cancel: 'Cancelar',
  sent: 'Conversación reportada. El agente revisor la analizará en breve.',
  failed: 'No pudimos enviar el reporte. Inténtalo de nuevo.',
  lastReport: 'Ver el último reporte en HappSea',
};

const enabled = window.chatwootConfig?.happseaAgentReviewsEnabled;
const hubUrl = window.chatwootConfig?.happseaHubUrl || '';
const dialog = ref(null);
const note = ref('');
const busy = ref(false);
const error = ref('');
const review = ref(null);
const pending = computed(() => ['QUEUED', 'RUNNING'].includes(review.value?.status));
const reviewUrl = computed(() =>
  hubUrl && review.value ? `${hubUrl}/agent-reviews?review=${encodeURIComponent(review.value.id)}` : ''
);
let timer;
let generation = 0;

async function load(conversationId, version) {
  try {
    const { data } = await ConversationApi.getAgentReview(conversationId);
    if (version !== generation) return;
    review.value = data.review;
  } catch {
    /* The button stays usable; submitting reports its own error. */
  } finally {
    if (version === generation && pending.value) {
      timer = setTimeout(() => load(conversationId, version), 8000);
    }
  }
}

function openDialog() {
  error.value = '';
  dialog.value?.open();
}

async function submit() {
  if (busy.value) return;
  // An older status request must not replace a newly submitted review.
  generation += 1;
  clearTimeout(timer);
  const version = generation;
  const conversationId = props.conversationId;
  busy.value = true;
  error.value = '';
  try {
    const { data } = await ConversationApi.submitAgentReview(conversationId, note.value.trim());
    if (version !== generation) return;
    review.value = { id: data.id, status: 'QUEUED' };
    note.value = '';
    dialog.value?.close();
    useAlert(COPY.sent);
    await load(conversationId, version);
  } catch {
    if (version === generation) error.value = COPY.failed;
  } finally {
    if (version === generation) busy.value = false;
  }
}

watch(() => props.conversationId, id => {
  generation += 1;
  clearTimeout(timer);
  review.value = null;
  note.value = '';
  error.value = '';
  busy.value = false;
  if (enabled && id) load(id, generation);
}, { immediate: true });
onUnmounted(() => { generation += 1; clearTimeout(timer); });
</script>

<template>
  <template v-if="enabled">
    <button
      type="button"
      :disabled="pending"
      :title="pending ? COPY.pendingHint : COPY.buttonHint"
      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium border transition-all duration-150 bg-n-alpha-1 border-n-weak text-n-slate-10 hover:bg-n-alpha-2 hover:text-n-slate-11 disabled:opacity-60 disabled:cursor-not-allowed"
      @click="openDialog"
    >
      <span class="i-ph-flag size-3.5 flex-shrink-0" :class="pending ? 'text-n-amber-9' : ''" />
      <span>{{ pending ? COPY.pending : COPY.button }}</span>
    </button>
    <Dialog
      ref="dialog"
      :title="COPY.title"
      :description="COPY.description"
      :confirm-button-label="COPY.confirm"
      :cancel-button-label="COPY.cancel"
      :is-loading="busy"
      width="md"
      @confirm="submit"
    >
      <div class="flex flex-col gap-2">
        <TextArea
          v-model="note"
          :label="COPY.noteLabel"
          :placeholder="COPY.notePlaceholder"
          :max-length="2000"
          show-character-count
          auto-height
          min-height="5rem"
          autofocus
        />
        <p v-if="error" role="alert" class="mb-0 text-xs text-n-ruby-11">{{ error }}</p>
        <a
          v-if="reviewUrl"
          :href="reviewUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-xs text-n-slate-11 underline underline-offset-2 hover:text-n-slate-12"
        >
          {{ COPY.lastReport }}
        </a>
      </div>
    </Dialog>
  </template>
</template>
