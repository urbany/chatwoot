<script setup>
import { computed } from 'vue';

const props = defineProps({
  item: { type: Object, required: true },
  stageId: { type: String, required: true },
  isDropTarget: { type: Boolean, default: false },
});

const emit = defineEmits(['edit', 'delete', 'dragover']);

const details = computed(() => props.item.item_details || {});

const handleDragStart = event => {
  event.dataTransfer.setData(
    'application/kanban-item',
    JSON.stringify({ itemId: props.item.id, sourceStageId: props.stageId })
  );
  event.dataTransfer.effectAllowed = 'move';
};

const handleEdit = () => emit('edit', props.item);
const handleDelete = () => emit('delete', props.item);
</script>

<template>
  <div
    draggable="true"
    class="p-3 rounded-lg bg-n-alpha-3 border border-n-weak cursor-grab active:cursor-grabbing hover:shadow-sm transition-shadow"
    :class="{ 'mt-6': isDropTarget }"
    @dragstart="handleDragStart"
    @dragover="emit('dragover', $event)"
    @click="handleEdit"
  >
    <div class="flex items-start justify-between gap-2">
      <h4 class="text-sm font-medium text-n-slate-12 line-clamp-2">
        {{ details.title || item.id }}
      </h4>
      <button
        class="text-n-slate-10 hover:text-n-ruby-9"
        @click.stop="handleDelete"
      >
        <span class="i-lucide-trash-2 size-4" />
      </button>
    </div>
    <p
      v-if="details.description"
      class="mt-1 text-xs text-n-slate-11 line-clamp-2"
    >
      {{ details.description }}
    </p>
    <div class="flex items-center gap-2 mt-2">
      <span
        v-if="details.priority"
        class="px-1.5 py-0.5 text-[10px] uppercase rounded bg-n-slate-3 text-n-slate-11"
      >
        {{ details.priority }}
      </span>
      <span
        v-if="details.value"
        class="ml-auto text-xs font-medium text-n-slate-12"
      >
        {{ details.value }}
      </span>
    </div>
  </div>
</template>
