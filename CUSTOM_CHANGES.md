# Custom Changes

## Version v4.13.0-whatsapp-templates-v3

Date: 2026-04-26

Builds on `v4.13.0-whatsapp-templates-v2` with better production observability and a more state-aware WhatsApp template editor. The settings page now surfaces pending, rejected, paused, and disabled templates more clearly, applies immediate local create/delete updates while background sync reconciles later, and the backend logs template operations with account, inbox, and channel context.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/controllers/api/v1/accounts/concerns/whatsapp_health_management.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `app/javascript/dashboard/store/modules/inboxes.js`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`

### Backend

- Adds structured `[WHATSAPP TEMPLATES]` logs for template fetch, create, delete, and manual sync flows.
- Enriches the template API response shape with `rejected_reason`, `sub_category`, and `parameter_format` so the UI can explain review state.
- Returns a template-shaped create response so the frontend can insert newly submitted templates immediately instead of waiting for the async sync job.
- Keeps background sync in place after create/delete and manual sync, but makes the async nature explicit in the UI and logs.
- Uses WhatsApp Graph API `v25.0` for template CRUD and related template status/list flows in this iteration.

### Frontend

- Removes the duplicate frontend sync enqueue after create/delete because the backend already schedules `Channels::Whatsapp::TemplatesSyncJob`.
- Adds template state summary chips and filtering for approved, pending, rejected, paused, disabled, and other states.
- Shows rejection reasons and extra template metadata directly in the settings page cards.
- Inserts newly created templates locally with pending status and removes deleted templates locally before background reconciliation completes.
- Rewords the sync button flow so users are told sync is asynchronous rather than implying an immediate refresh.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Breaking Changes

- None for existing inbox configuration.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- This iteration includes a template-endpoint WhatsApp Graph API upgrade to `v25.0`; it is no longer the original low-risk "no Graph version change" patch shape.
- Create/delete state is reflected in the UI immediately, but final review status still depends on the async background template sync.

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
