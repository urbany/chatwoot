<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const previewBody = computed(
  () =>
    props.template.body.text ||
    t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.PREVIEW_BODY_PLACEHOLDER')
);

const visibleButtons = computed(() => {
  if (!props.template.buttons.include) return [];

  return props.template.buttons.items.filter(button => button.text);
});

const hasTextHeader = computed(
  () =>
    props.template.header.include &&
    props.template.header.format === 'TEXT' &&
    props.template.header.text
);

const hasMediaHeader = computed(
  () => props.template.header.include && props.template.header.format !== 'TEXT'
);

const mediaHeaderIcon = computed(() => {
  const iconMap = {
    IMAGE: 'i-lucide-image',
    VIDEO: 'i-lucide-video',
    DOCUMENT: 'i-lucide-file-text',
  };

  return iconMap[props.template.header.format] || 'i-lucide-file';
});

const mediaFormatLabel = computed(() => {
  const labels = {
    IMAGE: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.IMAGE'),
    VIDEO: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.VIDEO'),
    DOCUMENT: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.DOCUMENT'),
  };

  return labels[props.template.header.format] || '';
});

const buttonIcon = button => {
  const iconMap = {
    QUICK_REPLY: 'i-lucide-reply',
    URL: 'i-lucide-external-link',
    COPY_CODE: 'i-lucide-copy',
  };

  return iconMap[button.type] || 'i-lucide-reply';
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <p class="m-0 text-sm font-medium text-n-slate-11">
      {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.PREVIEW_TITLE') }}
    </p>
    <div
      class="flex justify-center min-h-[32rem] p-6 overflow-hidden rounded-xl bg-gradient-to-b from-n-teal-2 to-n-slate-2 outline outline-1 outline-n-weak"
    >
      <div class="flex flex-col justify-end w-full max-w-sm">
        <div
          class="self-end max-w-80 overflow-hidden rounded-xl bg-n-surface-1 text-n-slate-12 shadow-sm divide-y divide-n-weak"
        >
          <div class="p-3">
            <div
              v-if="hasMediaHeader"
              class="flex items-center justify-center h-32 mb-3 rounded-lg bg-n-alpha-2 text-n-slate-11"
            >
              <img
                v-if="
                  template.header.mediaUrl && template.header.format === 'IMAGE'
                "
                :src="template.header.mediaUrl"
                class="object-cover w-full h-full rounded-lg"
                alt=""
              />
              <div v-else class="flex flex-col items-center gap-2">
                <Icon :icon="mediaHeaderIcon" class="size-6" />
                <span class="text-xs font-medium">
                  {{ mediaFormatLabel }}
                </span>
              </div>
            </div>
            <p
              v-if="hasTextHeader"
              class="mb-2 text-sm font-semibold text-n-slate-12 whitespace-pre-wrap"
            >
              {{ template.header.text }}
            </p>
            <p class="m-0 text-sm whitespace-pre-wrap text-n-slate-12">
              {{ previewBody }}
            </p>
            <p
              v-if="template.footer.include && template.footer.text"
              class="mt-3 mb-0 text-xs text-n-slate-10 whitespace-pre-wrap"
            >
              {{ template.footer.text }}
            </p>
            <p class="mt-2 mb-0 text-[0.6875rem] text-right text-n-slate-10">
              {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.PREVIEW_TIME') }}
            </p>
          </div>
          <div v-if="visibleButtons.length" class="divide-y divide-n-weak">
            <div
              v-for="button in visibleButtons"
              :key="`${button.type}-${button.text}`"
              class="flex items-center justify-center p-3"
            >
              <Button
                link
                blue
                size="sm"
                :icon="buttonIcon(button)"
                :label="button.text"
                class="hover:!no-underline"
                type="button"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
