# Custom Changes

## Version v4.13.0-whatsapp-templates-v8

Date: 2026-05-11

Fixes the WhatsApp agent header injection so it applies consistently to session messages sent by human agents from the dashboard UI across all WhatsApp providers. The backend now injects the agent `available_name` (`display_name` with fallback to `name`) for Cloud, 360dialog, and interactive WhatsApp messages without exposing that header in the composer textarea, while leaving bot and API-triggered sends unchanged.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb`

### Backend

- Moves WhatsApp header formatting into `Whatsapp::Providers::BaseService` so all providers share the same injection logic.
- Applies the header to text messages, attachment captions, and interactive message bodies for both WhatsApp Cloud and 360dialog providers when the message was flagged by the dashboard UI as a human agent send.
- Uses `available_name` so `display_name` is preferred and `name` is used automatically when no public name is set.
- Leaves bot sends, external/API-triggered sends, and template message payloads unchanged in this iteration.

### Frontend

- Adds an internal-only payload flag in the dashboard reply flow so the backend can distinguish UI agent sends from other message sources while keeping the header hidden from the composer.

### Upgrade Notes

- WhatsApp session messages now show the agent public name at the top when present, with automatic fallback to the regular name.

## Version v4.13.0-whatsapp-templates-v7

Date: 2026-05-11

**RELEASE NOTE**: This is the final production release combining v5 + v6 + v7 iterations into a single squashed commit. It delivers WhatsApp agent display name headers via backend injection.

Implements WhatsApp agent identification through backend display_name header injection (instead of signature footer transformation or frontend injection overrides). This is the definitive version; intermediate patches v5 and v6 have been deprecated and removed.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Backend

- Adds WhatsApp message header injection in `WhatsappCloudService` using `message.sender.display_name` (fallback to sender name) with format `*Display Name:*` followed by one newline.
- Applies the same header to text messages and attachment captions (where captions are supported) so WhatsApp output is consistent.
- Keeps message rendering pipeline unchanged for non-WhatsApp channels.

### Frontend

- Reverts WhatsApp-specific frontend signature overrides introduced in v6.
- Restores the default signature toggle behavior and default editor signature handling across channels.
- Removes WhatsApp-only payload injection from `ReplyBox` so WhatsApp header behavior is backend-driven.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this patch.

### Breaking Changes

- None for existing inbox configuration.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Agent display names now drive the WhatsApp header prefix sent to customers.
- Signature behavior in the composer is back to Chatwoot default behavior.

## Version v4.13.0-whatsapp-templates-v6

Date: 2026-05-08

Builds on `v4.13.0-whatsapp-templates-v5` with a WhatsApp signature fix: signature is now enabled by default for WhatsApp, hidden from the editor text area, and injected only at send time.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue`
- (MODIFIED) `app/services/messages/markdown_renderer_service.rb`
- (MODIFIED) `spec/services/messages/markdown_renderer_service_spec.rb`

### Backend

- Reverts the v5 markdown renderer signature transformation in `Messages::MarkdownRendererService`.
- Keeps WhatsApp markdown rendering behavior aligned with upstream to avoid signature parsing side effects.

### Frontend

- Enables signature by default for WhatsApp channels when no explicit UI setting exists yet.
- Stops appending signature text into the reply editor for WhatsApp channels.
- Injects signature only when constructing WhatsApp send payloads (including attachment captions) in `ReplyBox`.
- Uses the format `**signature:**` followed by one newline and message content for WhatsApp message payloads.
- Keeps non-WhatsApp channels on existing signature behavior.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this patch.

### Breaking Changes

- None for existing inbox configuration.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Existing drafts with footer-style signatures are normalized by removing the in-editor footer signature for WhatsApp.
- Signature visibility in editor remains unchanged for non-WhatsApp channels.

## Version v4.13.0-whatsapp-templates-v5

Date: 2026-05-08

Builds on `v4.13.0-whatsapp-templates-v4` with WhatsApp-only operator signature formatting that moves the signature from the footer to the top of the outgoing message in bold.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/services/messages/markdown_renderer_service.rb`
- (MODIFIED) `spec/services/messages/markdown_renderer_service_spec.rb`

### Backend

- Adds a WhatsApp-only signature transformation in `Messages::MarkdownRendererService` that rewrites the existing footer signature pattern (`--`) into a top header before markdown rendering.
- Formats WhatsApp signatures as bold header text followed by a single newline and the original message body.
- Preserves fallback behavior when no signature footer exists, so non-signature messages continue unchanged.
- Applies the same behavior to Twilio inboxes when the medium is WhatsApp.

### Frontend

- No frontend changes in this iteration.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this patch.

### Breaking Changes

- None for existing inbox configuration.
- Signature repositioning applies only to WhatsApp channel rendering.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Existing operator signatures continue to be configured through the same profile setting.
- Other channels keep the previous signature behavior (footer style), while WhatsApp now renders signatures at the top.

## Version v4.13.0-whatsapp-templates-v4

Date: 2026-04-26

Builds on `v4.13.0-whatsapp-templates-v3` with production timeout recovery for WhatsApp Cloud template create and delete flows. When Meta applies a template change but the synchronous Chatwoot request times out, the provider now rechecks Graph API by template name and returns the upstream state when available. If the timeout remains unresolved, Chatwoot still enqueues a background template sync so the inbox cache converges automatically.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Backend

- Adds a typed WhatsApp template timeout error so controller handling can distinguish provider timeouts from ordinary validation and API failures.
- Rechecks the WhatsApp Cloud `message_templates` endpoint by template name after create and delete timeouts and treats the operation as successful when Meta already applied the change.
- Enqueues `Channels::Whatsapp::TemplatesSyncJob` when a create or delete timeout cannot be reconciled immediately so the local `message_templates` cache still refreshes.
- Returns a clearer user-facing timeout message that explains template state will sync shortly instead of implying an unknown failure.

### Frontend

- No frontend changes in this iteration.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this iteration.

### Breaking Changes

- None for existing inbox configuration.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- This release specifically addresses production cases where Meta creates a template upstream but Chatwoot times out before receiving the response.
- If a provider timeout still cannot be reconciled inline, allow the queued background template sync to refresh the local template list.

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
