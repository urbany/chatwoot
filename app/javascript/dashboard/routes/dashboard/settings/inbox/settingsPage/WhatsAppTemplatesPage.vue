<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import whatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

import WhatsAppTemplateEditorDialog from './whatsappTemplates/WhatsAppTemplateEditorDialog.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const STATUS_ORDER = [
  'PENDING',
  'REJECTED',
  'PAUSED',
  'DISABLED',
  'APPROVED',
  'UNKNOWN',
];

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const templates = ref([]);
const isLoading = ref(false);
const isRefreshing = ref(false);
const isCreating = ref(false);
const isDeleting = ref(false);
const error = ref(null);
const isEditorOpen = ref(false);
const deleteDialog = ref(null);
const selectedTemplate = ref(null);
const activeStatusFilter = ref('ALL');

const inboxId = computed(() => route.params.inboxId);
const currentInbox = computed(() =>
  props.inbox?.id
    ? props.inbox
    : store.getters['inboxes/getInbox'](inboxId.value)
);
const isWhatsAppCloudInbox = computed(
  () => currentInbox.value?.provider === 'whatsapp_cloud'
);
const deleteConfirmDescription = computed(() =>
  t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_CONFIRM', {
    name: selectedTemplate.value?.name || '',
  })
);
const totalTemplatesLabel = computed(() =>
  t('INBOX_MGMT.WHATSAPP_TEMPLATES.SUMMARY', {
    count: templates.value.length,
  })
);
const statusLabels = computed(() => ({
  APPROVED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.APPROVED'),
  PENDING: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING'),
  REJECTED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REJECTED'),
  PAUSED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PAUSED'),
  DISABLED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.DISABLED'),
  UNKNOWN: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.UNKNOWN'),
}));
const statusHints = computed(() => ({
  APPROVED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.APPROVED'),
  PENDING: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.PENDING'),
  REJECTED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.REJECTED'),
  PAUSED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.PAUSED'),
  DISABLED: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.DISABLED'),
  UNKNOWN: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS_HINTS.UNKNOWN'),
}));

const normalizeStatus = status => status?.toUpperCase() || 'UNKNOWN';

const getStatusRank = status => {
  const normalizedStatus = normalizeStatus(status);
  const index = STATUS_ORDER.indexOf(normalizedStatus);
  return index === -1 ? STATUS_ORDER.length : index;
};

const compareTemplates = (leftTemplate, rightTemplate) => {
  const statusDifference =
    getStatusRank(leftTemplate.status) - getStatusRank(rightTemplate.status);

  if (statusDifference !== 0) {
    return statusDifference;
  }

  return (leftTemplate.name || '').localeCompare(rightTemplate.name || '');
};

const setTemplates = nextTemplates => {
  templates.value = [...(nextTemplates || [])].sort(compareTemplates);

  const availableStatuses = new Set(
    templates.value.map(template => normalizeStatus(template.status))
  );

  if (
    activeStatusFilter.value !== 'ALL' &&
    !availableStatuses.has(activeStatusFilter.value)
  ) {
    activeStatusFilter.value = 'ALL';
  }
};

const templateKey = template =>
  `${template.name || ''}:${template.language || ''}`;

const upsertTemplate = template => {
  const normalizedStatus = normalizeStatus(template.status);
  const nextTemplates = templates.value.filter(
    currentTemplate => templateKey(currentTemplate) !== templateKey(template)
  );

  if (
    activeStatusFilter.value !== 'ALL' &&
    activeStatusFilter.value !== normalizedStatus
  ) {
    activeStatusFilter.value = normalizedStatus;
  }

  setTemplates([template, ...nextTemplates]);
};

const removeTemplatesByName = templateName => {
  setTemplates(
    templates.value.filter(template => template.name !== templateName)
  );
};

const statusCounts = computed(() =>
  templates.value.reduce((counts, template) => {
    const normalizedStatus = normalizeStatus(template.status);
    return {
      ...counts,
      [normalizedStatus]: (counts[normalizedStatus] || 0) + 1,
    };
  }, {})
);

const getStatusLabel = status =>
  statusLabels.value[normalizeStatus(status)] || normalizeStatus(status);

const getStatusHint = status =>
  statusHints.value[normalizeStatus(status)] || '';

const statusFilters = computed(() => {
  const filters = [
    {
      key: 'ALL',
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FILTERS.ALL'),
      count: templates.value.length,
    },
  ];

  STATUS_ORDER.filter(status => statusCounts.value[status]).forEach(status => {
    filters.push({
      key: status,
      label: getStatusLabel(status),
      count: statusCounts.value[status],
    });
  });

  Object.keys(statusCounts.value)
    .filter(status => !STATUS_ORDER.includes(status))
    .sort()
    .forEach(status => {
      filters.push({
        key: status,
        label: getStatusLabel(status),
        count: statusCounts.value[status],
      });
    });

  return filters;
});

const filteredTemplates = computed(() => {
  if (activeStatusFilter.value === 'ALL') {
    return templates.value;
  }

  return templates.value.filter(
    template => normalizeStatus(template.status) === activeStatusFilter.value
  );
});

const fetchTemplates = async () => {
  isLoading.value = true;
  error.value = null;
  try {
    const response = await whatsappChannelAPI.getTemplates(inboxId.value);
    setTemplates(response.data || []);
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
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_REQUESTED'));
  } catch (errorResponse) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isRefreshing.value = false;
  }
};

const createTemplate = async templatePayload => {
  isCreating.value = true;
  try {
    const createdTemplate = await store.dispatch(
      'inboxes/createWhatsAppTemplate',
      {
        inboxId: inboxId.value,
        template: templatePayload,
      }
    );
    upsertTemplate(createdTemplate);
    isEditorOpen.value = false;
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SUCCESS.CREATE'));
  } catch (errorResponse) {
    const message =
      errorResponse.response?.data?.errors?.[0] ||
      t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.ERROR.CREATE_FAILED');
    useAlert(message);
  } finally {
    isCreating.value = false;
  }
};

const openDeleteDialog = template => {
  selectedTemplate.value = template;
  deleteDialog.value?.open();
};

const clearSelectedTemplate = () => {
  selectedTemplate.value = null;
};

const deleteSelectedTemplate = async () => {
  if (!selectedTemplate.value) return;

  isDeleting.value = true;
  try {
    const templateName = selectedTemplate.value.name;
    await store.dispatch('inboxes/deleteWhatsAppTemplate', {
      inboxId: inboxId.value,
      name: templateName,
    });
    removeTemplatesByName(templateName);
    deleteDialog.value?.close();
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SUCCESS.DELETE'));
  } catch (errorResponse) {
    const message =
      errorResponse.response?.data?.errors?.[0] ||
      t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.ERROR.DELETE_FAILED');
    useAlert(message);
  } finally {
    isDeleting.value = false;
  }
};

const getStatusColor = status => {
  const colors = {
    APPROVED:
      'text-green-700 bg-green-50 dark:text-green-400 dark:bg-green-900/30',
    PENDING:
      'text-yellow-700 bg-yellow-50 dark:text-yellow-400 dark:bg-yellow-900/30',
    REJECTED: 'text-red-700 bg-red-50 dark:text-red-400 dark:bg-red-900/30',
    PAUSED:
      'text-orange-700 bg-orange-50 dark:text-orange-400 dark:bg-orange-900/30',
    DISABLED:
      'text-slate-700 bg-slate-100 dark:text-slate-300 dark:bg-slate-700/70',
  };
  return (
    colors[normalizeStatus(status)] ||
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
      <div class="flex flex-wrap items-center justify-end gap-2">
        <Button
          v-if="isWhatsAppCloudInbox"
          icon="i-lucide-plus"
          :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.NEW_TEMPLATE')"
          :disabled="isLoading"
          @click="isEditorOpen = true"
        />
        <Button
          faded
          slate
          icon="i-lucide-refresh-ccw"
          :class="{ '[&_.i-lucide-refresh-ccw]:animate-spin': isRefreshing }"
          :disabled="isRefreshing || isLoading"
          :label="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON')
          "
          @click="refreshTemplates"
        />
      </div>
    </div>

    <div
      class="mb-4 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-800/80 dark:text-slate-300"
    >
      {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_HINT') }}
    </div>

    <div v-if="!isLoading && templates.length" class="mb-4 flex flex-col gap-3">
      <div class="text-sm font-medium text-slate-700 dark:text-slate-300">
        {{ totalTemplatesLabel }}
      </div>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="filter in statusFilters"
          :key="filter.key"
          type="button"
          class="inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm transition-colors"
          :class="
            activeStatusFilter === filter.key
              ? 'border-slate-900 bg-slate-900 text-white dark:border-slate-100 dark:bg-slate-100 dark:text-slate-900'
              : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300 hover:text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:border-slate-600 dark:hover:text-slate-100'
          "
          @click="activeStatusFilter = filter.key"
        >
          <span>{{ filter.label }}</span>
          <span
            class="rounded-full px-2 py-0.5 text-xs"
            :class="
              activeStatusFilter === filter.key
                ? 'bg-white/20 text-white dark:bg-slate-900/15 dark:text-slate-900'
                : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-200'
            "
          >
            {{ filter.count }}
          </span>
        </button>
      </div>
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

    <div
      v-else-if="filteredTemplates.length === 0"
      class="flex flex-col items-center justify-center h-64 text-slate-500 dark:text-slate-400"
    >
      <p class="text-lg font-medium">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.NO_FILTER_MATCH') }}
      </p>
      <p class="mt-2 text-sm text-center max-w-xl">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_HINT') }}
      </p>
    </div>

    <div v-else class="grid grid-cols-1 gap-4">
      <div
        v-for="template in filteredTemplates"
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
                {{ getStatusLabel(template.status) }}
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
            <p
              v-if="getStatusHint(template.status)"
              class="mt-2 text-sm text-slate-600 dark:text-slate-300"
            >
              {{ getStatusHint(template.status) }}
            </p>
          </div>
          <Button
            v-if="isWhatsAppCloudInbox"
            icon="i-lucide-trash"
            slate
            ghost
            type="button"
            :disabled="isDeleting"
            :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_TEMPLATE')"
            @click="openDeleteDialog(template)"
          />
        </div>

        <div
          v-if="template.rejected_reason"
          class="mb-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-900/40 dark:bg-red-950/40 dark:text-red-300"
        >
          <span class="font-medium">
            {{ `${$t('INBOX_MGMT.WHATSAPP_TEMPLATES.REJECTED_REASON')}:` }}
          </span>
          {{ template.rejected_reason }}
        </div>

        <div
          v-if="template.sub_category || template.parameter_format"
          class="mb-3 flex flex-wrap gap-2 text-xs text-slate-500 dark:text-slate-400"
        >
          <span
            v-if="template.sub_category"
            class="rounded-full bg-slate-100 px-2 py-1 dark:bg-slate-900/60"
          >
            {{ `${$t('INBOX_MGMT.WHATSAPP_TEMPLATES.SUB_CATEGORY')}:` }}
            {{ template.sub_category }}
          </span>
          <span
            v-if="template.parameter_format"
            class="rounded-full bg-slate-100 px-2 py-1 dark:bg-slate-900/60"
          >
            {{ `${$t('INBOX_MGMT.WHATSAPP_TEMPLATES.PARAMETER_FORMAT')}:` }}
            {{ template.parameter_format }}
          </span>
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

    <WhatsAppTemplateEditorDialog
      v-model:open="isEditorOpen"
      :is-saving="isCreating"
      @save="createTemplate"
    />

    <Dialog
      ref="deleteDialog"
      type="alert"
      :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_TEMPLATE')"
      :description="deleteConfirmDescription"
      :confirm-button-label="
        $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_TEMPLATE')
      "
      :cancel-button-label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.CANCEL')"
      :is-loading="isDeleting"
      @confirm="deleteSelectedTemplate"
      @close="clearSelectedTemplate"
    />
  </div>
</template>
