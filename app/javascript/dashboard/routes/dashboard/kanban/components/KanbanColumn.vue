<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  items: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'move',
  'reorder',
  'addItem',
  'editItem',
  'deleteItem',
]);

const { t } = useI18n();
const dragOverIndex = ref(-1);
const isDraggingOver = ref(false);

const columnStyle = computed(() => ({
  borderTopColor: props.stage.color || '#64748b',
}));

const handleDragOver = event => {
  event.preventDefault();
  isDraggingOver.value = true;
};

const handleDragLeave = () => {
  isDraggingOver.value = false;
  dragOverIndex.value = -1;
};

const handleDrop = event => {
  event.preventDefault();
  isDraggingOver.value = false;

  const data = event.dataTransfer.getData('application/kanban-item');
  if (!data) return;

  const { itemId, sourceStageId } = JSON.parse(data);
  if (sourceStageId === props.stage.id && dragOverIndex.value === -1) return;

  const position =
    dragOverIndex.value >= 0 ? dragOverIndex.value : props.items.length;

  if (sourceStageId !== props.stage.id) {
    emit('move', { itemId, stageId: props.stage.id, position });
  } else if (dragOverIndex.value !== -1) {
    emit('reorder', { itemId, position });
  }

  dragOverIndex.value = -1;
};

const handleCardDragOver = (event, index) => {
  event.preventDefault();
  event.stopPropagation();
  dragOverIndex.value = index;
};

const handleAdd = () => emit('addItem', props.stage.id);
const handleEdit = item => emit('editItem', item);
const handleDelete = item => emit('deleteItem', item);
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-72 h-full rounded-lg bg-n-alpha-black2 border-t-4"
    :style="columnStyle"
    @dragover="handleDragOver"
    @dragleave="handleDragLeave"
    @drop="handleDrop"
  >
    <div class="flex items-center justify-between px-3 py-2">
      <h3 class="text-sm font-medium text-n-slate-12">{{ stage.name }}</h3>
      <span class="text-xs text-n-slate-11">{{ items.length }}</span>
    </div>

    <div
      class="flex-1 overflow-y-auto px-2 pb-2 space-y-2"
      :class="{ 'bg-n-alpha-2': isDraggingOver }"
    >
      <KanbanCard
        v-for="(item, index) in items"
        :key="item.id"
        :item="item"
        :stage-id="stage.id"
        :is-drop-target="dragOverIndex === index"
        @dragover="handleCardDragOver($event, index)"
        @edit="handleEdit"
        @delete="handleDelete"
      />
      <div
        v-if="items.length === 0"
        class="flex items-center justify-center py-8 text-sm text-n-slate-11"
      >
        {{ t('KANBAN.NO_ITEMS') }}
      </div>
    </div>

    <div class="p-2 border-t border-n-weak">
      <Button
        variant="ghost"
        size="sm"
        class="w-full"
        :label="t('KANBAN.NEW_ITEM')"
        @click="handleAdd"
      />
    </div>
  </div>
</template>
