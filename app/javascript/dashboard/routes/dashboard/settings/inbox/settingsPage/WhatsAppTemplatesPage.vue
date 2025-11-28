<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import whatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';

const route = useRoute();
const templates = ref([]);
const isLoading = ref(false);

const inboxId = computed(() => route.params.inboxId);

const fetchTemplates = async () => {
  isLoading.value = true;
  try {
    const response = await whatsappChannelAPI.getTemplates(inboxId.value);
    templates.value = response.data || [];
  } catch (error) {
    useAlert(error.message || 'Failed to fetch WhatsApp templates');
  } finally {
    isLoading.value = false;
  }
};

const getStatusColor = status => {
  const colors = {
    APPROVED: 'text-green-600 bg-green-50',
    PENDING: 'text-yellow-600 bg-yellow-50',
    REJECTED: 'text-red-600 bg-red-50',
  };
  return colors[status?.toUpperCase()] || 'text-gray-600 bg-gray-50';
};

const getCategoryBadge = category => {
  const badges = {
    MARKETING: 'text-purple-600 bg-purple-50',
    UTILITY: 'text-blue-600 bg-blue-50',
    AUTHENTICATION: 'text-indigo-600 bg-indigo-50',
  };
  return badges[category?.toUpperCase()] || 'text-gray-600 bg-gray-50';
};

const getTemplateBody = components => {
  if (!components || !Array.isArray(components)) return '';
  const bodyComponent = components.find(c => c.type === 'BODY');
  return bodyComponent?.text || '';
};

onMounted(() => {
  fetchTemplates();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-2xl font-semibold text-slate-900">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.TITLE') }}
        </h3>
        <p class="mt-1 text-sm text-slate-600">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DESCRIPTION') }}
        </p>
      </div>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center h-64">
      <div class="flex items-center gap-2 text-slate-600">
        <span class="animate-spin h-5 w-5 border-2 border-slate-300 border-t-woot-500 rounded-full"></span>
        <span>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LOADING') }}</span>
      </div>
    </div>

    <div v-else-if="templates.length === 0" class="flex flex-col items-center justify-center h-64 text-slate-500">
      <p class="text-lg font-medium">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.NO_TEMPLATES') }}</p>
      <p class="mt-2 text-sm">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.NO_TEMPLATES_HINT') }}</p>
    </div>

    <div v-else class="grid grid-cols-1 gap-4">
      <div
        v-for="template in templates"
        :key="`${template.name}-${template.language}`"
        class="bg-white border border-slate-200 rounded-lg p-4 hover:border-slate-300 transition-colors"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="flex-1">
            <h4 class="text-lg font-semibold text-slate-900">{{ template.name }}</h4>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-xs px-2 py-1 rounded-full font-medium" :class="getStatusColor(template.status)">
                {{ template.status?.toUpperCase() }}
              </span>
              <span v-if="template.category" class="text-xs px-2 py-1 rounded-full font-medium" :class="getCategoryBadge(template.category)">
                {{ template.category }}
              </span>
              <span class="text-xs text-slate-500">{{ template.language }}</span>
            </div>
          </div>
        </div>

        <div v-if="getTemplateBody(template.components)" class="mt-3 p-3 bg-slate-50 rounded border border-slate-200">
          <p class="text-sm text-slate-700 whitespace-pre-wrap">{{ getTemplateBody(template.components) }}</p>
        </div>

        <div v-if="template.components && template.components.length > 1" class="mt-3">
          <details class="text-sm">
            <summary class="cursor-pointer text-woot-500 hover:text-woot-600 font-medium">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.VIEW_DETAILS') }}
            </summary>
            <div class="mt-2 space-y-2">
              <div
                v-for="(component, index) in template.components"
                :key="index"
                class="p-2 bg-white border border-slate-200 rounded"
              >
                <span class="text-xs font-semibold text-slate-600">{{ component.type }}</span>
                <p v-if="component.text" class="text-xs text-slate-700 mt-1">{{ component.text }}</p>
                <span v-if="component.format" class="text-xs text-slate-500">({{ component.format }})</span>
              </div>
            </div>
          </details>
        </div>
      </div>
    </div>
  </div>
</template>
