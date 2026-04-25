<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  COMPONENT_TYPES,
  VARIABLE_PATTERN,
  processVariable,
} from 'dashboard/helper/templateHelper';

import EditorSidebar from './EditorSidebar.vue';
import TemplatePreviewBubble from './TemplatePreviewBubble.vue';

const props = defineProps({
  open: {
    type: Boolean,
    default: false,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:open', 'save']);

const { t } = useI18n();

const dialogRef = ref(null);

const createDefaultTemplate = () => ({
  name: '',
  language: 'en_US',
  category: 'UTILITY',
  header: { include: false, format: 'TEXT', text: '', mediaUrl: '' },
  body: { text: '' },
  footer: { include: false, text: '' },
  buttons: { include: false, items: [] },
});

const template = ref(createDefaultTemplate());

const extractVariables = text => {
  const matches = text.match(VARIABLE_PATTERN) || [];
  return [...new Set(matches.map(variable => processVariable(variable)))];
};

const buildTextExamples = text =>
  extractVariables(text).map(variable => `sample_${variable}`);

const hasValidHeader = computed(() => {
  if (!template.value.header.include) return true;
  if (template.value.header.format !== 'TEXT') return true;

  return Boolean(template.value.header.text.trim());
});

const visibleButtons = computed(() => {
  if (!template.value.buttons.include) return [];

  return template.value.buttons.items.filter(button => button.text.trim());
});

const hasValidButtons = computed(() =>
  visibleButtons.value.every(
    button => button.type !== 'URL' || Boolean(button.url.trim())
  )
);

const canSave = computed(
  () =>
    Boolean(template.value.name.trim()) &&
    Boolean(template.value.body.text.trim()) &&
    hasValidHeader.value &&
    hasValidButtons.value
);

const buildHeaderComponent = () => {
  if (!template.value.header.include) return null;

  const component = {
    type: COMPONENT_TYPES.HEADER,
    format: template.value.header.format,
  };

  if (template.value.header.format === 'TEXT') {
    component.text = template.value.header.text.trim();
    const examples = buildTextExamples(component.text);
    if (examples.length)
      component.example = { header_text: examples.slice(0, 1) };
  }

  return component;
};

const buildBodyComponent = () => {
  const component = {
    type: COMPONENT_TYPES.BODY,
    text: template.value.body.text.trim(),
  };
  const examples = buildTextExamples(component.text);
  if (examples.length) component.example = { body_text: [examples] };

  return component;
};

const buildFooterComponent = () => {
  if (!template.value.footer.include || !template.value.footer.text.trim()) {
    return null;
  }

  return {
    type: COMPONENT_TYPES.FOOTER,
    text: template.value.footer.text.trim(),
  };
};

const buildButtonsComponent = () => {
  if (!visibleButtons.value.length) return null;

  return {
    type: COMPONENT_TYPES.BUTTONS,
    buttons: visibleButtons.value.map(button => {
      const buttonPayload = {
        type: button.type,
        text: button.text.trim(),
      };

      if (button.type === 'URL') {
        buttonPayload.url = button.url.trim();
        if (extractVariables(buttonPayload.url).length) {
          buttonPayload.example = ['sample'];
        }
      }

      if (button.type === 'COPY_CODE') {
        buttonPayload.example = [button.text.trim()];
      }

      return buttonPayload;
    }),
  };
};

const buildPayload = () => ({
  name: template.value.name.trim(),
  language: template.value.language,
  category: template.value.category,
  components: [
    buildHeaderComponent(),
    buildBodyComponent(),
    buildFooterComponent(),
    buildButtonsComponent(),
  ].filter(Boolean),
});

const handleClose = () => {
  emit('update:open', false);
};

const handleCancel = () => {
  dialogRef.value?.close();
  handleClose();
};

const handleSave = () => {
  if (!canSave.value || props.isSaving) return;

  emit('save', buildPayload());
};

watch(
  () => props.open,
  async isOpen => {
    await nextTick();

    if (isOpen) {
      template.value = createDefaultTemplate();
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  },
  { immediate: true }
);
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    overflow-y-auto
    :title="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_22rem]">
      <div class="max-h-[70vh] overflow-y-auto pr-1">
        <EditorSidebar v-model="template" />
      </div>
      <TemplatePreviewBubble :template="template" />
    </div>

    <template #footer>
      <div class="flex justify-end w-full gap-3">
        <Button
          type="button"
          faded
          slate
          :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.CANCEL')"
          @click="handleCancel"
        />
        <Button
          type="button"
          :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SAVE')"
          :is-loading="isSaving"
          :disabled="!canSave || isSaving"
          @click="handleSave"
        />
      </div>
    </template>
  </Dialog>
</template>
