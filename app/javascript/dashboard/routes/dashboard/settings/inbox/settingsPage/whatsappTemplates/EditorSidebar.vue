<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import {
  VARIABLE_PATTERN,
  processVariable,
} from 'dashboard/helper/templateHelper';

const template = defineModel({ type: Object, required: true });

const { t } = useI18n();

const categoryOptions = computed(() => [
  {
    value: 'MARKETING',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.CATEGORIES.MARKETING'),
  },
  {
    value: 'UTILITY',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.CATEGORIES.UTILITY'),
  },
  {
    value: 'AUTHENTICATION',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.CATEGORIES.AUTHENTICATION'),
  },
]);

const headerFormatOptions = computed(() => [
  {
    value: 'TEXT',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.TEXT'),
  },
  {
    value: 'IMAGE',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.IMAGE'),
  },
  {
    value: 'VIDEO',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.VIDEO'),
  },
  {
    value: 'DOCUMENT',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FORMATS.DOCUMENT'),
  },
]);

const buttonTypeOptions = computed(() => [
  {
    value: 'QUICK_REPLY',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.BUTTON_TYPES.QUICK_REPLY'),
  },
  {
    value: 'URL',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.BUTTON_TYPES.URL'),
  },
  {
    value: 'COPY_CODE',
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.BUTTON_TYPES.COPY_CODE'),
  },
]);

const languageOptions = [
  { value: 'en_US', label: 'en_US' },
  { value: 'en', label: 'en' },
  { value: 'es', label: 'es' },
  { value: 'pt_BR', label: 'pt_BR' },
  { value: 'fr', label: 'fr' },
  { value: 'de', label: 'de' },
];

const extractVariables = text => {
  const matches = text.match(VARIABLE_PATTERN) || [];
  return [...new Set(matches.map(variable => processVariable(variable)))];
};

const bodyVariables = computed(() =>
  extractVariables(template.value.body.text)
);

const slugifyName = value =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, '_')
    .replace(/_{2,}/g, '_')
    .replace(/^_+|_+$/g, '');

const updateTemplateName = value => {
  template.value.name = slugifyName(value);
};

const addButton = () => {
  if (template.value.buttons.items.length >= 3) return;

  template.value.buttons.items.push({
    type: 'QUICK_REPLY',
    text: '',
    url: '',
  });
};

const removeButton = index => {
  template.value.buttons.items.splice(index, 1);
};

const shouldShowUrlInput = button => button.type === 'URL';

const variableHintExamples = {
  first: '{{1}}',
  second: '{{2}}',
};

const variableLabel = variable => `{{${variable}}}`;
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="grid gap-4">
      <Input
        :model-value="template.name"
        :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.NAME')"
        :placeholder="
          t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.NAME_PLACEHOLDER')
        "
        @update:model-value="updateTemplateName"
      />

      <div class="grid grid-cols-2 gap-3">
        <label class="flex flex-col gap-1 text-heading-3 text-n-slate-12">
          {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.LANGUAGE') }}
          <Select v-model="template.language" :options="languageOptions" />
        </label>
        <label class="flex flex-col gap-1 text-heading-3 text-n-slate-12">
          {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.CATEGORY') }}
          <Select v-model="template.category" :options="categoryOptions" />
        </label>
      </div>
    </div>

    <SettingsToggleSection
      v-model="template.header.include"
      :header="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SECTIONS.HEADER')"
    >
      <template v-if="template.header.include" #editor>
        <div class="grid gap-3">
          <label
            class="flex flex-col gap-1 text-sm font-medium text-n-slate-12"
          >
            {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.FORMAT') }}
            <Select
              v-model="template.header.format"
              :options="headerFormatOptions"
            />
          </label>
          <Input
            v-if="template.header.format === 'TEXT'"
            v-model="template.header.text"
            :label="
              t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.HEADER_TEXT')
            "
            maxlength="60"
          />
          <Input
            v-else
            v-model="template.header.mediaUrl"
            :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.MEDIA_URL')"
            :placeholder="
              t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.MEDIA_URL_PLACEHOLDER')
            "
          />
        </div>
      </template>
    </SettingsToggleSection>

    <SettingsToggleSection
      model-value
      hide-toggle
      :header="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SECTIONS.BODY')"
    >
      <template #editor>
        <div class="grid gap-3">
          <TextArea
            v-model="template.body.text"
            :placeholder="
              t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.BODY_PLACEHOLDER')
            "
            :max-length="1024"
            show-character-count
            auto-height
            min-height="7rem"
          />
          <p class="m-0 text-xs text-n-slate-11">
            {{
              t(
                'INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.VARIABLE_HINT',
                variableHintExamples
              )
            }}
          </p>
          <div v-if="bodyVariables.length" class="flex flex-wrap gap-2">
            <span
              v-for="variable in bodyVariables"
              :key="variable"
              class="px-2 py-1 text-xs font-medium rounded-lg bg-n-alpha-2 text-n-slate-12"
            >
              {{ variableLabel(variable) }}
            </span>
          </div>
        </div>
      </template>
    </SettingsToggleSection>

    <SettingsToggleSection
      v-model="template.footer.include"
      :header="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SECTIONS.FOOTER')"
    >
      <template v-if="template.footer.include" #editor>
        <Input
          v-model="template.footer.text"
          :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.FOOTER_TEXT')"
          maxlength="60"
        />
      </template>
    </SettingsToggleSection>

    <SettingsToggleSection
      v-model="template.buttons.include"
      :header="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.SECTIONS.BUTTONS')"
    >
      <template v-if="template.buttons.include" #editor>
        <div class="grid gap-3">
          <div
            v-for="(button, index) in template.buttons.items"
            :key="index"
            class="grid grid-cols-[minmax(8rem,1fr)_minmax(10rem,1fr)_auto] gap-2 items-end"
          >
            <label
              class="flex flex-col gap-1 text-sm font-medium text-n-slate-12"
            >
              {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.TYPE') }}
              <Select v-model="button.type" :options="buttonTypeOptions" />
            </label>
            <Input
              v-model="button.text"
              :label="
                t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.BUTTON_TEXT')
              "
              maxlength="25"
            />
            <Button
              icon="i-lucide-trash"
              slate
              ghost
              type="button"
              :title="t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_TEMPLATE')"
              @click="removeButton(index)"
            />
            <Input
              v-if="shouldShowUrlInput(button)"
              v-model="button.url"
              class="col-span-3"
              :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.FIELDS.URL')"
              :placeholder="
                t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.URL_PLACEHOLDER')
              "
            />
          </div>
          <Button
            type="button"
            faded
            slate
            size="sm"
            icon="i-lucide-plus"
            :disabled="template.buttons.items.length >= 3"
            :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.EDITOR.ADD_BUTTON')"
            @click="addButton"
          />
        </div>
      </template>
    </SettingsToggleSection>
  </div>
</template>
