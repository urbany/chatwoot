# Custom Changes Tracking

This document tracks all custom changes made to the Chatwoot codebase for easy porting to future versions.

## Version v4.12.1-whatsapp-templates

### Date
2026-04-07

### Features Added
- **WhatsApp Templates Management UI**
  - New settings page to view WhatsApp message templates
  - Displays template status (APPROVED, PENDING, REJECTED)
  - Shows template categories and components
  - Supports template refresh functionality

### Files Modified
```
app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb (NEW)
app/javascript/dashboard/api/channel/whatsappChannel.js (MODIFIED)
app/javascript/dashboard/i18n/locale/en/inboxMgmt.json (MODIFIED)
app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue (MODIFIED)
app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue (NEW)
config/routes.rb (MODIFIED)
.github/workflows/build-custom-docker.yml (NEW)
```

### Backend Changes
**Controller:** `app/controllers/api/v1/accounts/inboxes/whatsapp_templates_controller.rb`
- Authorization: Uses `InboxPolicy#show?` for access control
- Endpoint: `GET /api/v1/accounts/:account_id/inboxes/:inbox_id/whatsapp_templates`
- Features:
  - Validates WhatsApp inbox type
  - Fetches templates from `channel.message_templates`
  - Handles both array and hash template formats
  - Defensive coding with proper error handling

**Routes:** `config/routes.rb`
```ruby
resources :whatsapp_templates, only: [:index], module: :inboxes
```

### Frontend Changes
**API Client:** `app/javascript/dashboard/api/channel/whatsappChannel.js`
```javascript
getTemplates(inboxId) {
  return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates`);
}
```

**Vue Component:** `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/WhatsAppTemplatesPage.vue`
- Composition API with `<script setup>`
- Features:
  - Template listing with status badges
  - Category indicators (MARKETING, UTILITY, AUTHENTICATION)
  - Component details view (expandable)
  - Refresh functionality to sync templates
  - Loading and empty states
  - Dark mode support

**Settings Integration:** `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- Added "WhatsApp Templates" tab for WhatsApp inboxes
- Tab only visible when `isAWhatsAppChannel` is true

### Translations
**File:** `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
```json
"WHATSAPP_TEMPLATES": {
  "TITLE": "WhatsApp Templates",
  "DESCRIPTION": "View and manage WhatsApp message templates...",
  "LOADING": "Loading templates...",
  "NO_TEMPLATES": "No templates found",
  "NO_TEMPLATES_HINT": "Create templates in your Meta Business Manager...",
  "VIEW_DETAILS": "View component details",
  "FORMAT": "({format})",
  "ERROR": {
    "FETCH_FAILED": "Failed to fetch WhatsApp templates. Please try again."
  }
}
```

### Docker/CI/CD
**Workflow:** `.github/workflows/build-custom-docker.yml`
- GitHub Container Registry (GHCR) builds
- Triggers: develop, master, tags (v*), manual
- Image: `ghcr.io/urbany/chatwoot`
- CE build (strips enterprise code)

### Database Changes
None (uses existing `message_templates` column on `channel_whatsapp` table)

### Configuration Changes
None required

### Breaking Changes
None

### Upgrade Notes for Future Versions
1. **Controller Location**: May need to check if `Api::V1::Accounts::BaseController` changes
2. **Policy Authorization**: Verify `InboxPolicy#show?` still exists in future versions
3. **Store Actions**: Uses `inboxes/syncTemplates` Vuex action - verify this still exists
4. **Icon Components**: Uses `dashboard/components-next/icon/Icon.vue` - verify this path
5. **Spinner Component**: Uses `dashboard/components-next/spinner/Spinner.vue` - verify this path

### Testing Notes
- Manual testing required with actual WhatsApp Business Account
- Templates must be created in Meta Business Manager first
- Sync happens automatically via existing `Channels::Whatsapp::TemplatesSyncSchedulerJob`

### Rollback Plan
If issues occur:
1. Remove WhatsApp Templates tab from Settings.vue
2. Remove controller file
3. Remove routes entry
4. Revert Docker image to previous version in K8s

## Future Versions

### v4.9.0 (planned)
- (to be filled when upgrading)

### v5.0.0 (planned)
- (to be filled when upgrading)
