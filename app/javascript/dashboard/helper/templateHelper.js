import {
  processVariable,
  buildWhatsAppProcessedParams,
  COMPONENT_TYPES as SHARED_COMPONENT_TYPES,
} from '@chatwoot/utils';

// Constants and pure template helpers are shared with the mobile app via
// @chatwoot/utils so the logic lives in one place.
export {
  MEDIA_FORMATS,
  findComponentByType,
  processVariable,
} from '@chatwoot/utils';

// @chatwoot/utils does not model FOOTER (composer never needs to fill it in),
// but the template editor still needs to add/remove a footer component.
export const COMPONENT_TYPES = { ...SHARED_COMPONENT_TYPES, FOOTER: 'FOOTER' };

export const VARIABLE_PATTERN = /{{([^}]+)}}/g;

export const DEFAULT_LANGUAGE = 'en';
export const DEFAULT_CATEGORY = 'UTILITY';

export const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

export const replaceTemplateVariables = (templateText, processedParams) => {
  return templateText.replace(VARIABLE_PATTERN, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.body?.[variableKey] || `{{${variable}}}`;
  });
};

// The media-header flag is derived from the template inside the shared helper;
// the second argument is kept for backwards-compatible call sites.
export const buildTemplateParameters = template =>
  buildWhatsAppProcessedParams(template);
