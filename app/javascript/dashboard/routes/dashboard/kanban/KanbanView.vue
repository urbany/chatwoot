<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanBoard from './components/KanbanBoard.vue';
import KanbanItemModal from './components/KanbanItemModal.vue';
import FunnelModal from './components/FunnelModal.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const funnels = useMapGetter('kanbanFunnels/getFunnels');
const items = useMapGetter('kanbanItems/getItems');
const funnelUIFlags = useMapGetter('kanbanFunnels/getUIFlags');
const itemUIFlags = useMapGetter('kanbanItems/getUIFlags');

const isFetchingFunnels = computed(() => funnelUIFlags.value.isFetching);
const isFetchingItems = computed(() => itemUIFlags.value.isFetching);

const selectedFunnelId = ref(Number(route.query.funnel_id) || null);
const itemModalRef = ref(null);
const funnelModalRef = ref(null);
const editingItem = ref(null);
const editingFunnel = ref(null);

const selectedFunnel = computed(() => {
  if (!selectedFunnelId.value) return null;
  return funnels.value.find(f => f.id === selectedFunnelId.value) || null;
});

const selectFunnel = funnelId => {
  selectedFunnelId.value = funnelId;
  router.replace({
    query: { ...route.query, funnel_id: funnelId },
  });
};

const fetchFunnels = async () => {
  await store.dispatch('kanbanFunnels/get');
  if (!selectedFunnelId.value && funnels.value.length > 0) {
    selectFunnel(funnels.value[0].id);
  }
};

const fetchItems = async () => {
  if (!selectedFunnelId.value) return;
  await store.dispatch('kanbanItems/get', { funnelId: selectedFunnelId.value });
};

const handleMove = async ({ itemId, stageId, position }) => {
  try {
    await store.dispatch('kanbanItems/move', {
      id: itemId,
      funnelStage: stageId,
      position,
    });
  } catch {
    useAlert(t('KANBAN.MOVE_ERROR'));
    await fetchItems();
  }
};

const handleReorder = async ({ itemId, position }) => {
  try {
    await store.dispatch('kanbanItems/reorder', { id: itemId, position });
  } catch {
    useAlert(t('KANBAN.MOVE_ERROR'));
    await fetchItems();
  }
};

const openNewItem = stageId => {
  editingItem.value = stageId ? { funnel_stage: stageId } : null;
  itemModalRef.value?.open();
};

const openEditItem = item => {
  editingItem.value = item;
  itemModalRef.value?.open();
};

const handleItemSaved = async () => {
  itemModalRef.value?.close();
  editingItem.value = null;
  await fetchItems();
};

const openNewFunnel = () => {
  editingFunnel.value = null;
  funnelModalRef.value?.open();
};

const openEditFunnel = () => {
  editingFunnel.value = selectedFunnel.value;
  funnelModalRef.value?.open();
};

const handleFunnelSaved = async () => {
  funnelModalRef.value?.close();
  editingFunnel.value = null;
  await fetchFunnels();
};

const handleDeleteItem = async item => {
  try {
    await store.dispatch('kanbanItems/delete', item.id);
    useAlert(t('KANBAN.DELETE_ITEM_SUCCESS'));
  } catch {
    useAlert(t('KANBAN.DELETE_ITEM_ERROR'));
  }
};

watch(selectedFunnelId, fetchItems);

onMounted(() => {
  fetchFunnels();
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden">
    <header
      class="flex items-center justify-between px-6 py-4 border-b border-n-weak"
    >
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-medium text-n-slate-12">
          {{ t('KANBAN.HEADER') }}
        </h1>
        <select
          v-if="funnels.length > 0"
          :value="selectedFunnelId || ''"
          class="h-9 px-3 text-sm rounded-lg outline outline-1 outline-n-weak bg-n-alpha-black2 text-n-slate-12"
          @change="selectFunnel(Number($event.target.value))"
        >
          <option value="" disabled>{{ t('KANBAN.SELECT_FUNNEL') }}</option>
          <option v-for="funnel in funnels" :key="funnel.id" :value="funnel.id">
            {{ funnel.name }}
          </option>
        </select>
      </div>
      <div class="flex items-center gap-2">
        <Button
          v-if="selectedFunnel"
          variant="ghost"
          size="sm"
          :label="t('KANBAN.EDIT_FUNNEL')"
          @click="openEditFunnel"
        />
        <Button
          size="sm"
          :label="t('KANBAN.NEW_FUNNEL')"
          @click="openNewFunnel"
        />
        <Button
          v-if="selectedFunnel"
          size="sm"
          :label="t('KANBAN.NEW_ITEM')"
          @click="openNewItem()"
        />
      </div>
    </header>

    <main class="flex-1 overflow-hidden">
      <div
        v-if="isFetchingFunnels || isFetchingItems"
        class="flex items-center justify-center w-full h-full"
      >
        <Spinner />
      </div>
      <div
        v-else-if="funnels.length === 0"
        class="flex flex-col items-center justify-center gap-4 p-8"
      >
        <p class="text-n-slate-11">{{ t('KANBAN.NO_FUNNELS') }}</p>
      </div>
      <KanbanBoard
        v-else-if="selectedFunnel"
        :funnel="selectedFunnel"
        :items="items"
        @move="handleMove"
        @reorder="handleReorder"
        @add-item="openNewItem"
        @edit-item="openEditItem"
        @delete-item="handleDeleteItem"
      />
    </main>

    <KanbanItemModal
      ref="itemModalRef"
      :funnel="selectedFunnel"
      :item="editingItem"
      @close="editingItem = null"
      @saved="handleItemSaved"
    />
    <FunnelModal
      ref="funnelModalRef"
      :funnel="editingFunnel"
      @close="editingFunnel = null"
      @saved="handleFunnelSaved"
    />
  </div>
</template>
