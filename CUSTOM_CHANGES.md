# Custom Changes

## Version v4.16.2-whatsapp-templates-v1

Date: 2026-07-29

Monthly port of the WhatsApp patch line (templates + editor, reactions, CSAT inline
processor, timeout recovery, agent-header truthfulness, `custom/` extension namespace)
onto upstream Chatwoot `v4.16.2`. Ported by cherry-picking the single commit at
`refs/heads/v4.16.0-whatsapp-templates-cumulative-v1` onto `refs/tags/v4.16.2`.

Three conflicts, all mechanical:

- `app/javascript/dashboard/components-next/message/bubbles/Base.vue`: kept both
  upstream's new `CaptainGenerationDetails`-wrapped meta display and the patch's
  `MessageReactions` component.
- `app/javascript/dashboard/components/ui/ContextMenu.vue`: pure formatting difference
  (upstream reflowed a one-line guard into a commented multi-line form); kept upstream's
  version, logic unchanged.
- `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`: kept both
  upstream's new `Icon` component registration and the patch's `WhatsAppTemplatesPage`
  (later removed — see below).

One additional non-conflicting merge required manual reconciliation:
`app/javascript/dashboard/helper/templateHelper.js`. Upstream moved
`MEDIA_FORMATS`/`COMPONENT_TYPES`/`findComponentByType`/`processVariable`/
`buildTemplateParameters` into the shared `@chatwoot/utils` package (bumped to `0.0.56`,
also used by the mobile app). The shared package's `COMPONENT_TYPES` does not include
`FOOTER` (the composer never fills one in) and does not export `VARIABLE_PATTERN`, both
of which the patch's template editor needs. Resolved by re-exporting the shared
constants/helpers directly, locally extending `COMPONENT_TYPES` with `FOOTER`, and
keeping a local `VARIABLE_PATTERN` export. `buildTemplateParameters` now delegates to
the shared `buildWhatsAppProcessedParams` (verified behaviorally equivalent to the
patch's previous manual implementation: body vars, media header incl. document
`media_name`, and URL/COPY_CODE button params).

One semantic fix needed beyond the mechanical cherry-pick: upstream `v4.16.1` added
`recipient_params` to `Whatsapp::Providers::BaseService`, routing Business-Scoped User
IDs (BSUID, coexistence contacts with no phone number) via a `recipient` field instead of
`to`. The patch's `custom/` overrides of `send_text_message`, `send_attachment_message`,
and `send_reaction` (`reaction_request_body`) fully replace those methods and had
hardcoded `to: phone_number`, silently dropping messages to BSUID contacts. Updated all
three to use `recipient_params(phone_number)` in
`custom/app/services/custom/whatsapp/providers/whatsapp_cloud_service.rb`.

Also removed the now-dead `Icon` component registration from `Settings.vue`: it was only
used by an Instagram restriction banner that upstream removed in `v4.16.1`
(`fix(instagram): remove resolved restriction banners`), and ESLint's
`vue/no-unused-components` flagged it once the banner markup was gone.

Audited the remaining upstream WhatsApp-related commits between `v4.16.0` and `v4.16.2`
(`d644c207f0` health monitoring, `166a41c31c` reply-window guard, `e65e18e9c5` phone
number normalization, `2144de92f2` coexistence conversation reuse, `b2716e15e1` number
deregistration) against every file the patch overrides via `custom/`. None of their
changed methods are shadowed by a `custom/` override, so no further fixes were needed.

### Files Modified

Same file set as `v4.16.0-whatsapp-templates-v1` (see that section below for the full
backend/frontend list), plus:

- (MODIFIED) `app/javascript/dashboard/components-next/message/bubbles/Base.vue` (conflict resolution)
- (MODIFIED) `app/javascript/dashboard/components/ui/ContextMenu.vue` (conflict resolution, no logic change)
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` (conflict resolution + removed dead `Icon` registration)
- (MODIFIED) `app/javascript/dashboard/helper/templateHelper.js` (re-aligned with `@chatwoot/utils` 0.0.56)
- (MODIFIED) `custom/app/services/custom/whatsapp/providers/whatsapp_cloud_service.rb` (BSUID recipient routing)

### Backend

- `Custom::Whatsapp::Providers::WhatsappCloudService#send_text_message`,
  `#send_attachment_message`, and `#reaction_request_body` now route Business-Scoped User
  ID recipients via `recipient_params`, matching upstream's `v4.16.1` BSUID fix instead of
  always sending `to: phone_number`.

### Frontend

- `templateHelper.js` now sources `MEDIA_FORMATS`, `findComponentByType`, and
  `processVariable` from `@chatwoot/utils` (matching upstream and the mobile app), while
  still locally providing `COMPONENT_TYPES.FOOTER` and `VARIABLE_PATTERN` for the
  template editor.

### Database

- No database changes beyond what `v4.16.0-whatsapp-templates-v1` already introduced.

### Configuration

- No new environment variables or application configuration.
- Create/delete are exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Upstream base: `v4.16.2`. Port source: `refs/heads/v4.16.0-whatsapp-templates-cumulative-v1`.
- The next monthly port source should be the cumulative helper branch created from this
  release: `refs/heads/v4.16.2-whatsapp-templates-cumulative-v1`.

## Version v4.16.0-whatsapp-templates-v1

Date: 2026-07-22

Monthly port of the WhatsApp patch line (templates + editor, reactions, CSAT inline
processor, timeout recovery, agent-header truthfulness, `custom/` extension namespace)
onto upstream Chatwoot `v4.16.0`. Ported by cherry-picking the single commit at
`refs/heads/v4.15.1-whatsapp-templates-cumulative-v5` onto `refs/tags/v4.16.0`.

Three conflicts, all mechanical:

- `app/javascript/dashboard/components-next/message/Message.vue`: kept both upstream's
  new `report` context-menu action (Captain) and the patch's `react` action.
- `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`: kept both
  upstream's new `Icon` component registration and the patch's `WhatsAppTemplatesPage`.
- `db/schema.rb`: kept upstream's higher schema version (`2026_07_13_184351`); the
  patch's `add_team_id_to_reporting_events` migration (`2026_06_25_000000`) is older and
  already reflected in the table body, so it doesn't move the version marker.

One semantic fix needed beyond the mechanical cherry-pick: upstream `v4.16.0` added a
`phone_number_id`/WABA cross-check to the OSS `validate_provider_config?` (guards the
embedded-to-manual transfer flow). The patch's `custom/` override of that method fully
replaces it for Bearer-header auth and had silently dropped the new check when carried
forward from the `v4.15.1` line (which didn't have it). Restored the check on top of the
patch's auth/logging style in
`custom/app/services/custom/whatsapp/providers/whatsapp_cloud_service.rb`, and updated
the corresponding stubs in `spec/models/channel/whatsapp_spec.rb` to use header-based
auth consistently across all three `validate_provider_config` examples.

Also fixed two pre-existing RuboCop offenses surfaced by the newer RuboCop config in
`v4.16.0` (`Metrics/ParameterLists`, `Rails/Blank`) in
`app/services/messages/reaction_update_service.rb` and
`app/services/whatsapp/send_reaction_service.rb`: the reaction service's `actor_type`/
`actor_id`/`actor_name` keyword params are now grouped into a single `actor:` hash.

### Files Modified

Same file set as `v4.15.1-whatsapp-templates-v5` (see that section below for the full
backend/frontend list), plus:

- (MODIFIED) `app/javascript/dashboard/components-next/message/Message.vue` (conflict resolution)
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` (conflict resolution)
- (MODIFIED) `db/schema.rb` (conflict resolution)
- (MODIFIED) `app/services/messages/reaction_update_service.rb` (rubocop fix)
- (MODIFIED) `app/services/whatsapp/send_reaction_service.rb` (rubocop fix)
- (MODIFIED) `custom/app/services/custom/whatsapp/incoming_message_base_service.rb` (call site update for `actor:` hash)
- (MODIFIED) `custom/app/services/custom/whatsapp/providers/whatsapp_cloud_service.rb` (restore phone_number_id check)
- (MODIFIED) `spec/models/channel/whatsapp_spec.rb` (stub updates)

### Backend

- `Custom::Whatsapp::Providers::WhatsappCloudService#validate_provider_config?` now
  performs the same WABA/phone_number_id verification as upstream when
  `provider_config` changes, in addition to the message-templates reachability check,
  using the patch's Bearer-header auth and template logging helpers.
- `Messages::ReactionUpdateService.new` now takes `actor: { type:, id:, name: }` instead
  of three separate `actor_type:`/`actor_id:`/`actor_name:` keywords (both call sites
  updated: `Whatsapp::SendReactionService` and
  `Custom::Whatsapp::IncomingMessageBaseService`).

### Database

- No database changes beyond what `v4.15.1-whatsapp-templates-v5` already introduced
  (`team_id` on `reporting_events`).

### Configuration

- No new environment variables or application configuration.
- Create/delete are exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.

### Upgrade Notes

- Upstream base: `v4.16.0`. Port source: `refs/heads/v4.15.1-whatsapp-templates-cumulative-v5`.
- The next monthly port source should be the cumulative helper branch created from this
  release: `refs/heads/v4.16.0-whatsapp-templates-cumulative-v1`.

## Version v4.15.1-whatsapp-templates-v5

Date: 2026-07-14

Builds on `v4.15.1-whatsapp-templates-v4`. `Messages::MessageBuilder` already accepted an `external_created_at` param (unix seconds) and stored it inside `content_attributes` via the `store :content_attributes, accessors: [..., :external_created_at, ...]` declaration on `Message`, but never applied it to the message's actual `created_at` column — messages backfilled by external integrations (e.g. the `whatsapp-2-chatwoot` backup middleware) always got the import time instead of their original timestamp, breaking chronological ordering and the displayed time. `external_created_at`, when present on the request, now also backdates the real `created_at` column, in addition to (not instead of) the existing `content_attributes` storage.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `.rubocop.yml`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`

### Backend

- `Messages::MessageBuilder#perform` now calls a new private `apply_external_created_at`, which sets `@message.created_at = Time.zone.at(params[:external_created_at].to_i)` before `save!`, when `external_created_at` is present on the request. The existing merge that stores `external_created_at` inside `content_attributes` is unchanged.
- `.rubocop.yml`: added `app/builders/messages/message_builder.rb` to the `Metrics/ClassLength` exclude list (same precedent as `app/models/message.rb` and `app/models/conversation.rb`) — the class was already at the 175-line cap before this addition.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- This release is a small additive bugfix on top of `v4.15.1-whatsapp-templates-v4`.
- The next monthly port source should be `refs/heads/v4.15.1-whatsapp-templates-cumulative-v5`.

## Version v4.15.1-whatsapp-templates-v4

Date: 2026-07-13

Pure internal refactor — **no functional changes** versus `v4.15.1-whatsapp-templates-v3`. Relocates almost the entire patch out of directly-edited upstream files into a new `custom/` extension namespace, mirroring how `enterprise/` already uses `prepend_mod_with`/`include_mod_with` (see `config/initializers/01_inject_enterprise_edition_module.rb`, `ChatwootApp.extensions`, `ChatwootApp.custom?`). Non-spec Ruby files with in-place OSS diffs dropped from 23 to 12, all but one of which is now a single one-time `Klass.prepend_mod_with('Klass')` line. The largest single-file diff (`whatsapp_cloud_service.rb`, 301 lines) drops to zero — that file is now byte-identical to upstream. The exact pattern (including which cases must stay inline — DSL macros like `store`/`delegate`, routes, i18n, migrations, `app/javascript/**`) is documented in `.claude/skills/chatwoot-whatsapp-templates-patch/references/modifications.md`.

Also includes two fixes surfaced while building this:

- **`lib/chatwoot_app.rb`**: `ChatwootApp.extensions` unconditionally included `'enterprise'` whenever `custom/` existed, regardless of whether `enterprise/` was actually present. The production CE Docker build (`build-custom-docker.yml`) always strips `enterprise/` entirely, so this would have crashed boot in production the moment `custom/` was introduced (hits a separate latent bug in `01_inject_enterprise_edition_module.rb#const_get_maybe_false`, where `mod&.const_defined?` only short-circuits on `nil`, not the `false` that a missing-namespace lookup returns). Fixed to only request an extension whose directory exists.
- **`config/locales/en.yml`**: restores the `csat.not_sent_due_to_cooldown` key, present on `v4.15.1-whatsapp-templates-cumulative-v3` (this release's port source) but missing from the `v3` release branch/tag itself — pre-existing drift between those two refs, not introduced here.

### Files Modified

13 new files under `custom/app/**` (the relocated `Custom::` modules), plus `config/application.rb` (wiring), `lib/chatwoot_app.rb` (extensions fix), and a single-line/hook-only touch on the 12 files listed in `references/modifications.md`'s `custom/` section. Full feature set (WhatsApp templates CRUD/editor, reactions, agent-header truthfulness, CSAT inline processor, team reporting) is unchanged from `v3` — see that version's changelog entries below for the original feature-level file lists.

### Frontend

No changes — this release only restructures backend Ruby overrides.

### Backend

No behavior changes. See the two fixes above.

### Database

No database changes. Schema and migrations are byte-identical to `v4.15.1-whatsapp-templates-v3`.

### Configuration

No new environment variables or application configuration.

### Upgrade Notes

- This release is a structural refactor of `v4.15.1-whatsapp-templates-v3`; behavior should be identical.
- The next monthly port source should be `refs/heads/v4.15.1-whatsapp-templates-cumulative-v4`.

## Version v4.15.1-whatsapp-templates-v2

Date: 2026-06-24

Builds on `v4.15.1-whatsapp-templates-v1` with two fixes: makes the CSAT comment optional in the survey and widget forms, and fixes WhatsApp help article insertion to include both the article title (bold) and URL instead of just the title.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/constants/editor.js`
- (MODIFIED) `app/javascript/shared/components/CustomerSatisfaction.vue`
- (MODIFIED) `app/javascript/survey/components/Feedback.vue`
- (MODIFIED) `app/services/messages/markdown_renderers/whats_app_renderer.rb`

### Frontend

- Removes required validation on the CSAT comment textarea in both the standalone survey page (`Feedback.vue`) and the widget (`CustomerSatisfaction.vue`). The submit button no longer requires a non-empty comment — only a rating is needed, matching the "Your feedback (optional)" placeholder text.
- Adds `link` to the WhatsApp channel's supported editor marks so `stripUnsupportedFormatting` no longer strips `[title](url)` markdown links when inserting help articles into a WhatsApp conversation.

### Backend

- Updates `WhatsAppRenderer#link` to output the link text wrapped in WhatsApp bold (`*text*`) followed by the URL, instead of just the URL. This ensures the help article title is preserved alongside the link in messages delivered to WhatsApp.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- This release is a bugfix iteration on top of `v4.15.1-whatsapp-templates-v1`.
- The next monthly port source should be `refs/heads/v4.15.1-whatsapp-templates-cumulative-v2`.

## Version v4.15.1-whatsapp-templates-v1

Date: 2026-06-17

Ports the WhatsApp templates patch line from `v4.14.1-whatsapp-templates-v5` onto upstream `v4.15.1`. This release keeps the full templates/editor feature, agent-header truthfulness for manual sends, template create/delete timeout recovery, WhatsApp reactions, and the custom CE Docker build workflow.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `.github/workflows/build-custom-docker.yml`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/concerns/whatsapp_health_management.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/conversations/messages_controller.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/javascript/dashboard/api/channel/whatsappChannel.js`
- (MODIFIED) `app/javascript/dashboard/api/inbox/message.js`
- (MODIFIED) `app/javascript/dashboard/components-next/message/Message.vue`
- (MODIFIED) `app/javascript/dashboard/components-next/message/MessageReactions.vue`
- (MODIFIED) `app/javascript/dashboard/components-next/message/bubbles/Base.vue`
- (MODIFIED) `app/javascript/dashboard/components/ui/ContextMenu.vue`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/helper/commons.js`
- (MODIFIED) `app/javascript/dashboard/helper/specs/commons.spec.js`
- (MODIFIED) `app/javascript/dashboard/helper/templateHelper.js`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/conversation.json`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- (MODIFIED) `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/EditorSidebar.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/TemplatePreviewBubble.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/WhatsAppTemplateEditorDialog.vue`
- (MODIFIED) `app/javascript/dashboard/store/modules/conversations/actions.js`
- (MODIFIED) `app/javascript/dashboard/store/modules/inboxes.js`
- (MODIFIED) `app/javascript/dashboard/store/modules/specs/conversations/actions.spec.js`
- (MODIFIED) `app/models/channel/whatsapp.rb`
- (MODIFIED) `app/models/message.rb`
- (ADDED) `app/services/concerns/whatsapp_agent_header_helper.rb`
- (ADDED) `app/services/messages/reaction_update_service.rb`
- (MODIFIED) `app/services/twilio/send_on_twilio_service.rb`
- (MODIFIED) `app/services/whatsapp/csat_template_service.rb`
- (MODIFIED) `app/services/whatsapp/incoming_message_base_service.rb`
- (MODIFIED) `app/services/whatsapp/incoming_message_service_helpers.rb`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (ADDED) `app/services/whatsapp/send_reaction_service.rb`
- (MODIFIED) `config/routes.rb`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`
- (MODIFIED) `spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb`
- (MODIFIED) `spec/jobs/webhooks/whatsapp_events_job_spec.rb`
- (MODIFIED) `spec/models/channel/whatsapp_spec.rb`
- (MODIFIED) `spec/services/twilio/send_on_twilio_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/csat_template_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Frontend

- Adds a WhatsApp Templates settings tab for WhatsApp channels with list, create, and delete functionality.
- Adds WhatsApp message reactions with reaction picker integration in the message context menu.
- Adds agent-header injection for manual outgoing WhatsApp messages so sender names are truthfully represented.
- Updates `ReplyBox` to set the `whatsapp_agent_header_enabled` flag on outgoing WhatsApp messages.

### Backend

- Adds `WhatsappTemplatesController` with `index`, `create`, and `destroy` endpoints nested under inboxes.
- Adds `create_template` and `delete_template` delegation on `Channel::Whatsapp` for WhatsApp Cloud API inboxes.
- Adds timeout recovery for template create/delete operations, polling Meta after a timeout to confirm state.
- Adds `WhatsappAgentHeaderHelper` and applies it to WhatsApp Cloud and Twilio WhatsApp message sends.
- Adds `Whatsapp::SendReactionService` and reaction handling in incoming/outgoing WhatsApp message services.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- Aligns with upstream WhatsApp Cloud Graph API versions (v14.0 for Business Account template operations, v13.0 default / v24.0 for phone message sends).

### Upgrade Notes

- Ported from `refs/heads/v4.14.1-whatsapp-templates-cumulative-v5` onto upstream `v4.15.1`.
- `EmojiInput.vue` was removed in upstream `v4.15.1`; the reaction suggestion polish from `v4.14.1-whatsapp-templates-v5` could not be applied to that file and may need re-implementation against the new emoji picker component if desired.
- The next monthly port source should be a new cumulative helper branch created from this release.

## Version v4.14.1-whatsapp-templates-v5

Date: 2026-06-11

Builds on `v4.14.1-whatsapp-templates-v4` with a UI polish pass for WhatsApp reactions. This iteration replaces the browser-native reaction chip tooltip with the same dashboard tooltip pattern already used on message avatars, and adds a curated row of WhatsApp-style reaction suggestions at the top of the picker.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/components-next/message/MessageReactions.vue`
- (MODIFIED) `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`
- (MODIFIED) `app/javascript/shared/components/emoji/EmojiInput.vue`

### Frontend

- Moves reaction chip hover text onto the dashboard tooltip system so actor names render consistently with the rest of the conversation UI.
- Adds a suggested reaction row to the picker for WhatsApp message reactions without changing other emoji picker call sites.
- Sets the suggested WhatsApp reactions to `👍`, `🧡`, `✅`, `🙏`, `😉`, `😢`, and `🎉`.

### Backend

- No backend changes.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- This release is a UI polish iteration on top of `v4.14.1-whatsapp-templates-v4`.
- The next monthly port source should be `refs/heads/v4.14.1-whatsapp-templates-cumulative-v5` once that helper branch is created from this release.

## Version v4.14.1-whatsapp-templates-v4

Date: 2026-06-11

Builds on `v4.14.1-whatsapp-templates-v3` with a follow-up fix for the WhatsApp reaction picker. The `React` action was visible again in `v3`, but opening the picker immediately shifted focus into the emoji search field, which caused the shared context menu wrapper to close before agents could choose a reaction.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/components/ui/ContextMenu.vue`

### Frontend

- Changes the shared context menu close behavior to only dismiss when focus leaves the menu subtree, instead of on every wrapper blur.
- Keeps the reaction picker open while `EmojiInput` auto-focuses its internal search field, so the emoji list remains interactive after clicking `React`.
- Limits the fix to the generic popover focus handling so existing message reaction rendering and backend behavior stay unchanged.

### Backend

- No backend changes.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- This release is a bugfix iteration on top of `v4.14.1-whatsapp-templates-v3`.
- The next monthly port source should be `refs/heads/v4.14.1-whatsapp-templates-cumulative-v4` once that helper branch is created from this release.

## Version v4.14.1-whatsapp-templates-v3

Date: 2026-06-11

Builds on `v4.14.1-whatsapp-templates-v2` with a UI fix for WhatsApp reactions. The reactions feature was present in `v2`, including footer rendering and backend support, but the message action trigger was still hidden so agents had no visible way to open the reaction picker from the conversation view.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/components-next/message/Message.vue`

### Frontend

- Restores the visible message action trigger by removing the forced hidden-button mode from the message context menu.
- Adds the expected named hover group on the message row so the ellipsis button appears on hover and the `React` action becomes reachable.
- Leaves the existing footer reaction display and reaction picker behavior unchanged apart from making the entry point visible again.

### Backend

- No backend changes.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- This release is a bugfix iteration on top of `v4.14.1-whatsapp-templates-v2`.
- The next monthly port source should be `refs/heads/v4.14.1-whatsapp-templates-cumulative-v3` once that helper branch is created from this release.

## Version v4.14.1-whatsapp-templates-v2

Date: 2026-06-09

Builds on `v4.14.1-whatsapp-templates-v1` by adding WhatsApp message reactions. The patch stores inbound webhook reactions on the referenced Chatwoot message without a schema migration, adds a Cloud-only outbound reaction API with the same 24-hour reply window guard used for WhatsApp replies, and renders grouped reaction chips in the message footer with an emoji picker in the message context menu.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/controllers/api/v1/accounts/conversations/messages_controller.rb`
- (MODIFIED) `app/javascript/dashboard/api/inbox/message.js`
- (MODIFIED) `app/javascript/dashboard/components-next/message/Message.vue`
- (ADDED) `app/javascript/dashboard/components-next/message/MessageReactions.vue`
- (MODIFIED) `app/javascript/dashboard/components-next/message/bubbles/Base.vue`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/conversation.json`
- (MODIFIED) `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`
- (MODIFIED) `app/javascript/dashboard/store/modules/conversations/actions.js`
- (MODIFIED) `app/javascript/dashboard/store/modules/specs/conversations/actions.spec.js`
- (MODIFIED) `app/models/channel/whatsapp.rb`
- (MODIFIED) `app/models/message.rb`
- (ADDED) `app/services/messages/reaction_update_service.rb`
- (MODIFIED) `app/services/whatsapp/incoming_message_base_service.rb`
- (MODIFIED) `app/services/whatsapp/incoming_message_service_helpers.rb`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (ADDED) `app/services/whatsapp/send_reaction_service.rb`
- (MODIFIED) `config/routes.rb`
- (MODIFIED) `spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb`
- (MODIFIED) `spec/jobs/webhooks/whatsapp_events_job_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Backend

- Persists reactions on `Message.content_attributes.reactions`, keyed by actor, so inbound and outbound reaction state updates reuse the existing message row and broadcast path.
- Handles inbound WhatsApp webhook reactions by locating the referenced message and upserting or removing the contact reaction instead of creating a synthetic message row.
- Adds a Cloud-only outbound `POST /messages/:id/reaction` API that validates message eligibility, enforces the existing 24-hour reply window, sends the Graph API reaction payload, and stores the business reaction on the target message.
- Maps Meta reaction failures such as `131009` to a user-facing error for expired reaction windows.

### Frontend

- Adds a message footer reaction component that groups reactions by emoji and exposes actor names on hover.
- Adds a `React` action to the message context menu for supported WhatsApp Cloud incoming messages and reuses the existing emoji picker UI.
- Wires the dashboard message API and store to update the message in place after a successful reaction response.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this patch.
- Outbound reactions are exposed only for WhatsApp Cloud API inboxes; inbound webhook reactions update the referenced message state without schema changes.

### Upgrade Notes

- This release is a straight feature iteration on top of `v4.14.1-whatsapp-templates-v1`.
- The next monthly port source should be `refs/heads/v4.14.1-whatsapp-templates-cumulative-v2` once that helper branch is created from this release.

## Version v4.14.1-whatsapp-templates-v1

Date: 2026-06-09

Ports the full `v4.14.0-whatsapp-templates-v2` patch line onto Chatwoot `v4.14.1`. The port was applied from `refs/heads/v4.14.0-whatsapp-templates-cumulative-v2` and merged cleanly apart from the expected mechanical updates in `Settings.vue` and `inboxMgmt.json` to preserve the upstream `v4.14.1` WhatsApp calling tab alongside the WhatsApp Templates tab.

### Files Modified

- (ADDED) `.github/workflows/build-custom-docker.yml`
- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/concerns/whatsapp_health_management.rb`
- (ADDED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/javascript/dashboard/api/channel/whatsappChannel.js`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/helper/commons.js`
- (MODIFIED) `app/javascript/dashboard/helper/specs/commons.spec.js`
- (MODIFIED) `app/javascript/dashboard/helper/templateHelper.js`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/EditorSidebar.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/TemplatePreviewBubble.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/WhatsAppTemplateEditorDialog.vue`
- (MODIFIED) `app/javascript/dashboard/store/modules/inboxes.js`
- (MODIFIED) `app/models/channel/whatsapp.rb`
- (ADDED) `app/services/concerns/whatsapp_agent_header_helper.rb`
- (MODIFIED) `app/services/twilio/send_on_twilio_service.rb`
- (MODIFIED) `app/services/whatsapp/csat_template_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `config/routes.rb`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`
- (MODIFIED) `spec/models/channel/whatsapp_spec.rb`
- (MODIFIED) `spec/services/twilio/send_on_twilio_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/csat_template_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Backend

- Preserves the nested WhatsApp template CRUD API, provider delegations, CSAT template integration, and WhatsApp Cloud template sync/cache behavior on top of upstream `v4.14.1`.
- Keeps the timeout recovery path for WhatsApp Cloud template create/delete calls so Meta-side template changes can still reconcile after request timeouts.
- Keeps WhatsApp manual UI sends using the explicit `content_attributes[:whatsapp_agent_header_enabled]` gate for the public-name header, while template sends remain header-free unless Meta actually returns one.
- Preserves provider-specific header injection helpers across WhatsApp Cloud, 360dialog, and Twilio WhatsApp sends.

### Frontend

- Preserves the WhatsApp Templates settings tab and editor flow while keeping upstream `v4.14.1` inbox tabs, including Voice and WhatsApp Calls, intact.
- Keeps the template helper/store/API updates, sync copy, status presentation, and live preview components.
- Preserves the optimistic reply bubble behavior so manual WhatsApp sends show the public-name header immediately and template sends stay truthful to the eventual stored content.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.
- No WhatsApp Graph API version upgrade in this patch.
- Create and delete remain exposed only for WhatsApp Cloud API inboxes; 360dialog remains read-only.
- The fork keeps `.github/workflows/build-custom-docker.yml`; the patched release tag for this line is `4.14.1-whatsapp-templates-v1`, while the mirrored upstream base tag remains `v4.14.1`.

### Upgrade Notes

- This release is a straight port of the full `v4.14.0-whatsapp-templates-v2` patch line onto upstream `v4.14.1`.
- The monthly port source for the next upgrade should be `refs/heads/v4.14.1-whatsapp-templates-cumulative-v1` once that helper branch is created from this release.

## Version 4.14.0-whatsapp-templates-v2

Date: 2026-05-20

Builds on `4.14.0-whatsapp-templates-v1` with a release engineering fix for the failed CE Docker build. This iteration restores valid JSON syntax in the inbox settings locale file and updates the custom Docker workflow trigger so patched release tags like `4.14.0-whatsapp-templates-v2` launch the build directly, while mirrored upstream tags such as `v4.14.0` remain untouched.

### Files Modified

- (MODIFIED) `.github/workflows/build-custom-docker.yml`
- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`

### Frontend

- Restores valid JSON syntax in `INBOX_MGMT.TABS` by adding the missing comma between `WHATSAPP_TEMPLATES` and `VOICE`.
- Unblocks the Vite JSON loader during assets precompile.

### Configuration

- Changes the custom Docker workflow tag trigger from generic `v*` to `*-whatsapp-templates-v*`.
- Ensures patched WhatsApp release tags trigger image builds while mirrored upstream Chatwoot tags do not start this custom workflow.

### Database

- No database changes.

### Upgrade Notes

- Use tag `4.14.0-whatsapp-templates-v2` for this fixed release.
- The upstream base tag remains `v4.14.0`.

## Version 4.14.0-whatsapp-templates-v1

Date: 2026-05-19

Ports the full `v4.13.0-whatsapp-templates-v12` cumulative patch line onto Chatwoot `v4.14.0`. This keeps the WhatsApp templates management UI and API, timeout recovery around WhatsApp Cloud template create/delete calls, manual-send agent header behavior, the template-header truthfulness fix, and the custom CE Docker build workflow. The port was applied from `refs/heads/v4.13.0-whatsapp-templates-cumulative-v12` and merged cleanly apart from mechanical updates in `Settings.vue`, `inboxMgmt.json`, and `whatsapp_cloud_service.rb`.

### Files Modified

- (ADDED) `.github/workflows/build-custom-docker.yml`
- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (MODIFIED) `app/controllers/api/v1/accounts/concerns/whatsapp_health_management.rb`
- (ADDED) `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- (MODIFIED) `app/javascript/dashboard/api/channel/whatsappChannel.js`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/helper/commons.js`
- (MODIFIED) `app/javascript/dashboard/helper/specs/commons.spec.js`
- (MODIFIED) `app/javascript/dashboard/helper/templateHelper.js`
- (MODIFIED) `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- (MODIFIED) `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/EditorSidebar.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/TemplatePreviewBubble.vue`
- (ADDED) `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/whatsappTemplates/WhatsAppTemplateEditorDialog.vue`
- (MODIFIED) `app/javascript/dashboard/store/modules/inboxes.js`
- (MODIFIED) `app/models/channel/whatsapp.rb`
- (ADDED) `app/services/concerns/whatsapp_agent_header_helper.rb`
- (MODIFIED) `app/services/twilio/send_on_twilio_service.rb`
- (MODIFIED) `app/services/whatsapp/csat_template_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `config/routes.rb`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`
- (MODIFIED) `spec/models/channel/whatsapp_spec.rb`
- (MODIFIED) `spec/services/twilio/send_on_twilio_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/csat_template_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`

### Backend

- Preserves the nested WhatsApp template CRUD API, provider delegations, CSAT template integration, and WhatsApp Cloud template sync/cache behavior.
- Keeps the timeout recovery path for create/delete so Meta-side template changes can still reconcile after a request timeout.
- Keeps WhatsApp manual UI sends using the explicit `content_attributes[:whatsapp_agent_header_enabled]` gate for the public-name header, while template sends stay header-free unless Meta actually returns one.
- Preserves provider-specific header injection helpers across WhatsApp Cloud, 360dialog, and Twilio WhatsApp sends.
- Keeps the Enterprise prepend hook in `WhatsappCloudService` while also retaining the upstream class-length lint footer introduced around `v4.14.0`.

### Frontend

- Preserves the WhatsApp Templates settings tab and editor flow while keeping upstream `v4.14.0` inbox tabs, including Voice configuration, intact.
- Keeps the local template helper/store/API updates, sync copy, status presentation, and live preview components.
- Preserves the optimistic reply bubble behavior so manual WhatsApp sends show the public-name header immediately and template sends stay truthful to the eventual stored content.

### Database

- No database changes.

### Configuration

- No new runtime environment variables or application configuration.
- The fork keeps `.github/workflows/build-custom-docker.yml`; the patched release tag for this line is `4.14.0-whatsapp-templates-v1`, while the mirrored upstream base tag remains `v4.14.0`.

### Upgrade Notes

- This release is a straight port of the full `v4.13.0-whatsapp-templates-v12` patch line onto upstream `v4.14.0`.
- The monthly port source for the next upgrade should be `refs/heads/v4.14.0-whatsapp-templates-cumulative-v1` once that helper branch is created from this release.

## Version v4.13.0-whatsapp-templates-v12

Date: 2026-05-19

Builds on `v4.13.0-whatsapp-templates-v11` with a truthfulness fix for WhatsApp agent headers. Manual custom WhatsApp sends still show the public-name header at the top, but template sends no longer persist or display that header in Chatwoot when Meta does not actually send it. The optimistic pending bubble for manual sends is also aligned with the final stored message so the agent sees the same header immediately.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (MODIFIED) `app/services/concerns/whatsapp_agent_header_helper.rb`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/javascript/dashboard/helper/commons.js`
- (MODIFIED) `app/javascript/dashboard/helper/specs/commons.spec.js`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`

### Backend

- Switches the WhatsApp agent-header gate from implicit `echo_id` detection to the explicit dashboard flag `content_attributes[:whatsapp_agent_header_enabled]`.
- Prevents template sends from persisting or displaying the agent header in Chatwoot, even when the optimistic send flow still carries an `echo_id`.
- Keeps manual WhatsApp dashboard sends storing the top header in markdown form so the final Chatwoot bubble matches the delivered manual message.

### Frontend

- Exposes the sender `available_name` in the reply payload so the optimistic pending bubble can mirror the public WhatsApp header.
- Builds pending-message `content` with the top header only for manual WhatsApp sends that explicitly enable the header.
- Leaves template pending messages header-free so Chatwoot no longer claims the header was sent when Meta template delivery did not include it.

### Database

- No database changes.

### Configuration

- No new environment variables or application configuration.

### Upgrade Notes

- Manual custom WhatsApp replies continue to show the public-name header both in Chatwoot and in the delivered message.
- WhatsApp template sends now show only the actual template content in Chatwoot, with no misleading top header.

## Version v4.13.0-whatsapp-templates-v11

Date: 2026-05-11

Final squashed release for the WhatsApp agent-name-at-the-top feature. This consolidates the earlier v7, v8, v9, and v10 iterations into one clean patch that applies only to human-agent dashboard sends on WhatsApp, keeps the name hidden from the composer, stores the sent Chatwoot message with the header at the top, and sends the correct formatted prefix through WhatsApp Cloud, 360dialog, and Twilio WhatsApp without duplication.

This release supersedes the intermediate top-name tags. The old tags can be removed after publishing this squashed version.

### Files Modified

- (MODIFIED) `CUSTOM_CHANGES.md`
- (MODIFIED) `app/builders/messages/message_builder.rb`
- (ADDED) `app/services/concerns/whatsapp_agent_header_helper.rb`
- (MODIFIED) `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- (MODIFIED) `app/services/whatsapp/providers/base_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- (MODIFIED) `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- (MODIFIED) `app/services/twilio/send_on_twilio_service.rb`
- (MODIFIED) `spec/builders/messages/message_builder_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb`
- (MODIFIED) `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`
- (MODIFIED) `spec/services/twilio/send_on_twilio_service_spec.rb`

### Backend

- Uses the agent `available_name` with fallback to `name`, so the public name is preferred automatically when present.
- Applies only to outgoing WhatsApp messages sent by human agents from the dashboard UI, identified through `echo_id` and guarded against bots, campaigns, automation, and non-UI/API sends.
- Persists the outgoing Chatwoot message content with a top header in storage-friendly markdown form so the sent bubble in Chatwoot also shows the agent name at the top.
- Reuses a shared `WhatsappAgentHeaderHelper` so Cloud, 360dialog, and Twilio WhatsApp all format the outgoing body consistently.
- Avoids double-prefixing when the stored message already contains the injected header before channel delivery.

### Upgrade Notes

- WhatsApp agent messages sent from the UI now show the agent name at the top both in Chatwoot and in the delivered WhatsApp message.
- Composer footer signatures are no longer used for WhatsApp in this flow, so the name stays hidden while typing and appears only in the sent output.

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
