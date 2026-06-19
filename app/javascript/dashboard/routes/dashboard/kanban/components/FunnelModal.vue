<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  funnel: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved']);

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);

const isEditing = computed(() => !!props.funnel?.id);

const DEFAULT_STAGES = [
  { id: 'todo', name: 'To Do', color: '#64748b' },
  { id: 'doing', name: 'Doing', color: '#3b82f6' },
  { id: 'done', name: 'Done', color: '#22c55e' },
];

const form = ref({
  name: '',
  description: '',
  stages: [...DEFAULT_STAGES],
  active: true,
});

const funnelUIFlags = computed(() => store.getters['kanbanFunnels/getUIFlags']);
const isSubmitting = computed(
  () => funnelUIFlags.value.isCreating || funnelUIFlags.value.isUpdating
);

const resetForm = () => {
  form.value = {
    name: '',
    description: '',
    stages: [...DEFAULT_STAGES],
    active: true,
  };
};

watch(
  () => props.funnel,
  newFunnel => {
    if (newFunnel?.id) {
      form.value = {
        name: newFunnel.name,
        description: newFunnel.description || '',
        stages: newFunnel.stages.map(s => ({ ...s })),
        active: newFunnel.active,
      };
    } else {
      resetForm();
    }
  },
  { immediate: true }
);

const addStage = () => {
  const id = `stage_${form.value.stages.length + 1}`;
  form.value.stages.push({ id, name: '', color: '#64748b' });
};

const removeStage = index => {
  form.value.stages.splice(index, 1);
};

const handleSubmit = async () => {
  try {
    const payload = { funnel: form.value };
    if (isEditing.value) {
      await store.dispatch('kanbanFunnels/update', {
        id: props.funnel.id,
        ...payload,
      });
    } else {
      await store.dispatch('kanbanFunnels/create', payload);
    }
    emit('saved');
  } catch {
    useAlert(
      isEditing.value
        ? t('KANBAN.UPDATE_FUNNEL_ERROR')
        : t('KANBAN.CREATE_FUNNEL_ERROR')
    );
  }
};

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="isEditing ? t('KANBAN.EDIT_FUNNEL') : t('KANBAN.NEW_FUNNEL')"
    :confirm-button-label="t('KANBAN.FORM.SAVE')"
    :is-loading="isSubmitting"
    :disable-confirm-button="!form.name || form.stages.length === 0"
    width="2xl"
    @confirm="handleSubmit"
    @close="emit('close')"
  >
    <div class="flex flex-col gap-4">
      <Input v-model="form.name" :label="t('KANBAN.FUNNEL_FORM.NAME')" />
      <Input
        v-model="form.description"
        :label="t('KANBAN.FUNNEL_FORM.DESCRIPTION')"
      />

      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <label class="text-heading-3 text-n-slate-12">{{
            t('KANBAN.FUNNEL_FORM.STAGES')
          }}</label>
          <button
            type="button"
            class="text-sm text-n-blue-11 hover:underline"
            @click="addStage"
          >
            {{ t('KANBAN.FUNNEL_FORM.ADD_STAGE') }}
          </button>
        </div>
        <div
          v-for="(stage, index) in form.stages"
          :key="index"
          class="grid grid-cols-[1fr_1fr_auto] gap-2 items-end"
        >
          <Input
            v-model="stage.name"
            :label="t('KANBAN.FUNNEL_FORM.STAGE_NAME')"
          />
          <Input
            v-model="stage.color"
            :label="t('KANBAN.FUNNEL_FORM.STAGE_COLOR')"
          />
          <button
            type="button"
            class="mb-3 text-n-slate-10 hover:text-n-ruby-9"
            @click="removeStage(index)"
          >
            <span class="i-lucide-trash-2 size-4" />
          </button>
        </div>
      </div>
    </div>
  </Dialog>
</template>
