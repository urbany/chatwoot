<script setup>
import { computed } from 'vue';
import KanbanColumn from './KanbanColumn.vue';

const props = defineProps({
  funnel: { type: Object, required: true },
  items: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'move',
  'reorder',
  'addItem',
  'editItem',
  'deleteItem',
]);

const stages = computed(() => props.funnel.stages || []);

const itemsByStage = stageId => {
  return props.items
    .filter(item => item.funnel_stage === stageId)
    .sort((a, b) => a.position - b.position);
};

const handleMove = payload => emit('move', payload);
const handleReorder = payload => emit('reorder', payload);
const handleAddItem = stageId => emit('addItem', stageId);
const handleEditItem = item => emit('editItem', item);
const handleDeleteItem = item => emit('deleteItem', item);
</script>

<template>
  <div class="flex h-full gap-4 px-6 py-4 overflow-x-auto">
    <KanbanColumn
      v-for="stage in stages"
      :key="stage.id"
      :stage="stage"
      :items="itemsByStage(stage.id)"
      @move="handleMove"
      @reorder="handleReorder"
      @add-item="handleAddItem"
      @edit-item="handleEditItem"
      @delete-item="handleDeleteItem"
    />
  </div>
</template>
