<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import whatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const templates = ref([]);
const isLoading = ref(false);
const isRefreshing = ref(false);
const error = ref(null);

const inboxId = computed(() => route.params.inboxId);

const fetchTemplates = async () => {
  isLoading.value = true;
  error.value = null;
  try {
    const response = await whatsappChannelAPI.getTemplates(inboxId.value);
    templates.value = response.data || [];
  } catch (errorResponse) {
    error.value =
      errorResponse.response?.data?.error ||
      t('INBOX_MGMT.WHATSAPP_TEMPLATES.ERROR.FETCH_FAILED');
    useAlert(error.value);
  } finally {
    isLoading.value = false;
  }
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', inboxId.value);
    await fetchTemplates();
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUCCESS'));
  } catch (errorResponse) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isRefreshing.value = false;
  }
};

const getStatusColor = status => {
  const colors = {
    APPROVED:
      'text-green-700 bg-green-50 dark:text-green-400 dark:bg-green-900/30',
    PENDING:
      'text-yellow-700 bg-yellow-50 dark:text-yellow-400 dark:bg-yellow-900/30',
    REJECTED: 'text-red-700 bg-red-50 dark:text-red-400 dark:bg-red-900/30',
  };
  return (
    colors[status?.toUpperCase()] ||
    'text-gray-700 bg-gray-50 dark:text-gray-400 dark:bg-gray-800'
  );
};

const getCategoryBadge = category => {
  const badges = {
    MARKETING:
      'text-purple-700 bg-purple-50 dark:text-purple-400 dark:bg-purple-900/30',
    UTILITY: 'text-blue-700 bg-blue-50 dark:text-blue-400 dark:bg-blue-900/30',
    AUTHENTICATION:
      'text-indigo-700 bg-indigo-50 dark:text-indigo-400 dark:bg-indigo-900/30',
  };
  return (
    badges[category?.toUpperCase()] ||
    'text-gray-700 bg-gray-50 dark:text-gray-400 dark:bg-gray-800'
  );
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
        <h3 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.TITLE') }}
        </h3>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DESCRIPTION') }}
        </p>
      </div>
      <button
        :disabled="isRefreshing || isLoading"
        class="flex items-center gap-2 px-4 py-2 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-slate-700 dark:text-slate-300"
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON') }}
      </button>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center h-64">
      <div
        class="flex flex-col items-center gap-3 text-slate-600 dark:text-slate-400"
      >
        <Spinner :size="32" />
        <span>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LOADING') }}</span>
      </div>
    </div>

    <div
      v-else-if="templates.length === 0"
      class="flex flex-col items-center justify-center h-64 text-slate-500 dark:text-slate-400"
    >
      <p class="text-lg font-medium">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.NO_TEMPLATES') }}
      </p>
      <p class="mt-2 text-sm">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.NO_TEMPLATES_HINT') }}
      </p>
    </div>

    <div v-else class="grid grid-cols-1 gap-4">
      <div
        v-for="template in templates"
        :key="`${template.name}-${template.language}`"
        class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg p-4 hover:border-slate-300 dark:hover:border-slate-600 transition-colors"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="flex-1">
            <h4
              class="text-lg font-semibold text-slate-900 dark:text-slate-100"
            >
              {{ template.name }}
            </h4>
            <div class="flex items-center gap-2 mt-1">
              <span
                class="text-xs px-2 py-1 rounded-full font-medium"
                :class="getStatusColor(template.status)"
              >
                {{ template.status?.toUpperCase() }}
              </span>
              <span
                v-if="template.category"
                class="text-xs px-2 py-1 rounded-full font-medium"
                :class="getCategoryBadge(template.category)"
              >
                {{ template.category }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-400">{{
                template.language
              }}</span>
            </div>
          </div>
        </div>

        <div
          v-if="getTemplateBody(template.components)"
          class="mt-3 p-3 bg-slate-50 dark:bg-slate-900/50 rounded border border-slate-200 dark:border-slate-700"
        >
          <p
            class="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap"
          >
            {{ getTemplateBody(template.components) }}
          </p>
        </div>

        <div
          v-if="template.components && template.components.length > 1"
          class="mt-3"
        >
          <details class="text-sm">
            <summary
              class="cursor-pointer text-woot-500 dark:text-woot-400 hover:text-woot-600 dark:hover:text-woot-300 font-medium"
            >
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.VIEW_DETAILS') }}
            </summary>
            <div class="mt-2 space-y-2">
              <div
                v-for="(component, index) in template.components"
                :key="index"
                class="p-2 bg-white dark:bg-slate-900/30 border border-slate-200 dark:border-slate-700 rounded"
              >
                <span
                  class="text-xs font-semibold text-slate-600 dark:text-slate-400"
                >
                  {{ component.type }}
                </span>
                <p
                  v-if="component.text"
                  class="text-xs text-slate-700 dark:text-slate-300 mt-1"
                >
                  {{ component.text }}
                </p>
                <span
                  v-if="component.format"
                  class="text-xs text-slate-500 dark:text-slate-400"
                >
                  {{
                    $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORMAT', {
                      format: component.format,
                    })
                  }}
                </span>
              </div>
            </div>
          </details>
        </div>
      </div>
    </div>
  </div>
</template>
