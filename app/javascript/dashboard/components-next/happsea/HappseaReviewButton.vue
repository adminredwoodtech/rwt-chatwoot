<script setup>
import { computed, ref, watch, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import ConversationApi from 'dashboard/api/conversations';

const props = defineProps({
  conversationId: { type: Number, required: true },
});
const { t } = useI18n();
const enabled = window.chatwootConfig?.happseaAgentReviewsEnabled;
const hubUrl = window.chatwootConfig?.happseaHubUrl || '';
const expanded = ref(false);
const note = ref('');
const busy = ref(false);
const error = ref(false);
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
    error.value = false;
  } catch {
    if (version === generation) error.value = true;
  } finally {
    if (version === generation && (pending.value || error.value)) {
      timer = setTimeout(() => load(conversationId, version), 8000);
    }
  }
}

async function submit() {
  if (busy.value) return;
  // An older status request must not replace a newly submitted review.
  generation += 1;
  clearTimeout(timer);
  const version = generation;
  const conversationId = props.conversationId;
  busy.value = true;
  error.value = false;
  try {
    const { data } = await ConversationApi.submitAgentReview(conversationId, note.value);
    if (version !== generation) return;
    review.value = { id: data.id, status: 'QUEUED' };
    expanded.value = false;
    note.value = '';
    clearTimeout(timer);
    await load(conversationId, version);
  } catch {
    if (version === generation) error.value = true;
  } finally {
    if (version === generation) busy.value = false;
  }
}

watch(() => props.conversationId, id => {
  generation += 1;
  clearTimeout(timer);
  review.value = null;
  note.value = '';
  error.value = false;
  busy.value = false;
  expanded.value = false;
  if (enabled && id) load(id, generation);
}, { immediate: true });
onUnmounted(() => { generation += 1; clearTimeout(timer); });
</script>

<template>
  <div v-if="enabled" class="space-y-2 border-t border-n-weak px-3 py-3">
    <button
      type="button"
      :disabled="pending || busy"
      :aria-expanded="expanded"
      class="flex w-full items-center justify-center gap-2 rounded-lg border border-n-weak px-3 py-2 text-xs font-medium text-n-slate-12 hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-teal-9 disabled:cursor-not-allowed disabled:opacity-60"
      @click="expanded = !expanded"
    >
      <span class="i-ph-clipboard-text size-4" />
      {{ pending ? t(`CONVERSATION.HAPPSEA_REVIEW.${review.status}`) : t('CONVERSATION.HAPPSEA_REVIEW.SUBMIT') }}
    </button>
    <form v-if="expanded" class="space-y-2" @submit.prevent="submit">
      <label :for="`review-note-${conversationId}`" class="block text-xs text-n-slate-11">
        {{ t('CONVERSATION.HAPPSEA_REVIEW.NOTE') }}
      </label>
      <textarea
        :id="`review-note-${conversationId}`"
        v-model="note"
        maxlength="2000"
        rows="3"
        class="w-full rounded-lg border border-n-weak bg-n-solid-1 p-2 text-xs text-n-slate-12"
        :placeholder="t('CONVERSATION.HAPPSEA_REVIEW.PLACEHOLDER')"
      />
      <button
        type="submit"
        :disabled="busy"
        class="w-full rounded-lg bg-n-teal-9 px-3 py-2 text-xs font-medium text-white disabled:opacity-60"
      >
        {{ busy ? t('CONVERSATION.HAPPSEA_REVIEW.SENDING') : t('CONVERSATION.HAPPSEA_REVIEW.CONFIRM') }}
      </button>
    </form>
    <a v-if="reviewUrl" :href="reviewUrl" target="_blank" rel="noopener noreferrer" class="block text-center text-xs text-n-teal-11 underline underline-offset-2">
      {{ t('CONVERSATION.HAPPSEA_REVIEW.OPEN') }}
    </a>
    <p v-if="error" role="alert" class="text-xs text-n-red-11">
      {{ t('CONVERSATION.HAPPSEA_REVIEW.ERROR') }}
    </p>
  </div>
</template>
