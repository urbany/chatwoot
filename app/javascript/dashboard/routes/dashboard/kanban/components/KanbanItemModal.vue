<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  funnel: { type: Object, default: null },
  item: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved']);

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);

const isEditing = computed(() => !!props.item?.id);

const form = ref({
  funnel_id: props.funnel?.id,
  funnel_stage: '',
  position: 0,
  item_details: {
    title: '',
    description: '',
    priority: 'medium',
    value: '',
  },
  conversation_display_id: null,
});

const itemUIFlags = computed(() => store.getters['kanbanItems/getUIFlags']);
const isSubmitting = computed(
  () => itemUIFlags.value.isCreating || itemUIFlags.value.isUpdating
);

const stages = computed(() => props.funnel?.stages || []);

const resetForm = () => {
  form.value = {
    funnel_id: props.funnel?.id,
    funnel_stage: stages.value[0]?.id || '',
    position: 0,
    item_details: {
      title: '',
      description: '',
      priority: 'medium',
      value: '',
    },
    conversation_display_id: null,
  };
};

watch(
  () => props.item,
  newItem => {
    if (newItem?.id) {
      form.value = {
        funnel_id: newItem.funnel_id,
        funnel_stage: newItem.funnel_stage,
        position: newItem.position,
        item_details: { ...newItem.item_details },
        conversation_display_id: newItem.conversation_display_id,
      };
    } else if (newItem?.funnel_stage) {
      resetForm();
      form.value.funnel_stage = newItem.funnel_stage;
    } else {
      resetForm();
    }
  },
  { immediate: true }
);

const handleSubmit = async () => {
  try {
    const payload = {
      ...form.value,
      item_details: {
        ...form.value.item_details,
        value: form.value.item_details.value
          ? Number(form.value.item_details.value)
          : null,
      },
    };

    if (isEditing.value) {
      await store.dispatch('kanbanItems/update', {
        id: props.item.id,
        kanban_item: payload,
      });
    } else {
      await store.dispatch('kanbanItems/create', { kanban_item: payload });
    }
    emit('saved');
  } catch {
    useAlert(
      isEditing.value
        ? t('KANBAN.UPDATE_ITEM_ERROR')
        : t('KANBAN.CREATE_ITEM_ERROR')
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
    :title="isEditing ? t('KANBAN.EDIT_ITEM') : t('KANBAN.NEW_ITEM')"
    :confirm-button-label="t('KANBAN.FORM.SAVE')"
    :is-loading="isSubmitting"
    :disable-confirm-button="!form.item_details.title"
    @confirm="handleSubmit"
    @close="emit('close')"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.item_details.title"
        :label="t('KANBAN.FORM.TITLE')"
        placeholder="Acme Corp deal"
      />
      <Input
        v-model="form.item_details.description"
        :label="t('KANBAN.FORM.DESCRIPTION')"
        placeholder="Follow up next week"
      />
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.item_details.value"
          type="number"
          :label="t('KANBAN.FORM.VALUE')"
        />
        <div class="flex flex-col gap-1">
          <label class="text-heading-3 text-n-slate-12">{{
            t('KANBAN.FORM.PRIORITY')
          }}</label>
          <select
            v-model="form.item_details.priority"
            class="h-10 px-3 text-sm rounded-lg outline outline-1 outline-n-weak bg-n-alpha-black2 text-n-slate-12"
          >
            <option value="low">{{ t('KANBAN.FORM.PRIORITY_LOW') }}</option>
            <option value="medium">
              {{ t('KANBAN.FORM.PRIORITY_MEDIUM') }}
            </option>
            <option value="high">{{ t('KANBAN.FORM.PRIORITY_HIGH') }}</option>
          </select>
        </div>
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-heading-3 text-n-slate-12">{{
          t('KANBAN.FORM.STAGE')
        }}</label>
        <select
          v-model="form.funnel_stage"
          class="h-10 px-3 text-sm rounded-lg outline outline-1 outline-n-weak bg-n-alpha-black2 text-n-slate-12"
        >
          <option v-for="stage in stages" :key="stage.id" :value="stage.id">
            {{ stage.name }}
          </option>
        </select>
      </div>
      <Input
        v-model="form.conversation_display_id"
        type="number"
        :label="t('KANBAN.FORM.CONVERSATION')"
      />
    </div>
  </Dialog>
</template>
