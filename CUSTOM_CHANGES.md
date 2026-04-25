# Custom Changes

## Version v4.13.0-whatsapp-templates-v2

Date: 2026-04-25

Adds a unified WhatsApp Templates Management feature for WhatsApp inboxes. The existing read-only templates viewer is extended with in-product template creation for WhatsApp Cloud API inboxes and delete support for existing templates. Template edit remains intentionally out of scope because Meta only allows limited edits for approved templates. This release keeps Chatwoot's existing WhatsApp Graph API version behavior unchanged to minimize upgrade risk.

### Files Modified

- (MODIFIED) `config/routes.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/models/channel/whatsapp.rb`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `app/services/whatsapp/csat_template_service.rb`
- (MODIFIED) `app/javascript/dashboard/api/channel/whatsappChannel.js`
- (MODIFIED) `app/javascript/dashboard/store/modules/inboxes.js`
- (MODIFIED) `app/javascript/dashboard/helper/templateHelper.js`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- (NEW) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/WhatsAppTemplateEditorDialog.vue`
- (NEW) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/EditorSidebar.vue`
- (NEW) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/TemplatePreviewBubble.vue`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- (NEW) `CUSTOM_CHANGES.md`

### Backend

- Extends the nested `whatsapp_templates` resource with create and destroy routes.
- Keeps template listing available to assigned inbox users through `InboxPolicy#show?`.
- Gates create and delete through `InboxPolicy#update?` and limits them to `whatsapp_cloud` inboxes.
- Adds provider-level `create_template` and `delete_template` delegation on `Channel::Whatsapp`.
- Implements WhatsApp Cloud API calls against the Business Account `/message_templates` endpoint.
- Reuses the provider template creation path from CSAT template generation to avoid duplicate POST implementations.
- Re-enqueues `Channels::Whatsapp::TemplatesSyncJob` after create and delete so the local JSONB template cache is refreshed.

### Frontend

- Adds `createTemplate` and `deleteTemplate` API methods for WhatsApp templates.
- Adds Vuex actions that call the new API methods and trigger template sync after successful create/delete.
- Adds a modal template builder to the existing WhatsApp Templates settings page.
- Adds a sidebar editor with collapsible Header, Footer, and Buttons sections plus a permanent Body section.
- Adds a live WhatsApp-style preview bubble that updates as users edit header, body, footer, and buttons.
- Adds a New Template action only for WhatsApp Cloud API inboxes.
- Adds per-template delete actions with confirmation.

### i18n

- Extends the existing English WhatsApp Templates block with editor, create, delete, preview, success, and error copy.
- No non-English locale files were changed.

### CI

- No CI configuration changes.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Breaking Changes

- None. The existing read-only viewer remains available for WhatsApp inboxes.
- Create and delete are only exposed for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Ensure WhatsApp Cloud inboxes have a valid `business_account_id` and API key in `provider_config`.
- After creating or deleting a template, allow the background sync job time to refresh the local template list.

### Rollback

- Revert the files listed above.
- No database rollback is required.
