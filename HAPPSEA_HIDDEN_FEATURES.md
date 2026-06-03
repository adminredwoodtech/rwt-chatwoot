# HappSea AI - Chatwoot Hidden Features Documentation

**Date**: February 4, 2026  
**Purpose**: Document all Chatwoot features hidden for MVP to maintain clarity on what's available if future requirements arise.

---

## Overview

For the HappSea AI MVP, several Chatwoot features were hidden to simplify the user interface and focus on core messaging functionality. All code remains intact and can be re-enabled via the `ENABLE_CHATWOOT_ADMIN` environment variable.

### Environment Toggle

```bash
ENABLE_CHATWOOT_ADMIN=true   # full admin UI (Reports, Campaigns, Help Center, etc.)
ENABLE_CHATWOOT_ADMIN=false  # light agent UI (default)
```

When enabled, the fork restores all sidebar items and frontend routes listed below. No code changes are required per client — only set the variable and restart containers.

---

## Hidden Features

### 1. **Captain AI Module** ❌

**Location**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (lines 305-376)

**What it does**:
- Built-in AI assistant for Chatwoot
- FAQs management
- Document management
- Scenarios configuration
- AI Playground for testing
- Inbox-specific AI settings
- Tools integration
- AI Guidelines and Guardrails

**Why hidden for MVP**:
- HappSea uses **Claude AI directly** via the Hub API
- No need for Chatwoot's built-in AI features
- Reduces complexity and confusion

**When to re-enable**:
- If you want to use Chatwoot's native AI features instead of Claude
- If you need multiple AI assistants with different configurations
- If you want AI features that don't require external API calls

**How to re-enable**:
Set `ENABLE_CHATWOOT_ADMIN=true` and restart Chatwoot (or uncomment the Captain block in `Sidebar.vue` for a permanent code change).

---

### 2. **Campaigns Module** ❌

**Location**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (lines 489-511)

**What it does**:
- **Live Chat Campaigns**: Proactive messages to website visitors
- **SMS Campaigns**: Bulk SMS messaging
- **WhatsApp Campaigns**: Bulk WhatsApp messaging

**Why hidden for MVP**:
- HappSea focuses on **reactive** customer service (customers initiate contact)
- No need for proactive marketing campaigns
- Claude AI handles all messaging through conversations

**When to re-enable**:
- If you want to send promotional messages to customers
- If you need to do bulk messaging for announcements
- If you want to engage website visitors proactively
- For marketing campaigns or special offers

**How to re-enable**:
Uncomment lines 489-511 in `Sidebar.vue`

---

### 3. **Help Center / Portals** ❌

**Location**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (lines 512-559)

**What it does**:
- **Articles**: Knowledge base articles
- **Categories**: Organize articles by topic
- **Locales**: Multi-language support for help content
- **Settings**: Configure help center appearance and behavior

**Why hidden for MVP**:
- No knowledge base needed for boat rental business
- All information is handled by Claude AI in conversations
- Reduces content management overhead

**When to re-enable**:
- If you want a public-facing FAQ/knowledge base
- If you need self-service support documentation
- If you want to reduce repetitive questions with articles
- For SEO benefits from help content

**How to re-enable**:
Uncomment lines 512-559 in `Sidebar.vue`

---

### 4. **Automation Rules** ❌

**Location**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (lines 613-619)

**What it does**:
- Automatic actions based on triggers (e.g., "if message contains X, then assign to Y")
- Auto-assignment rules
- Auto-tagging
- Auto-responses based on conditions
- Workflow automation

**Why hidden for MVP**:
- **Claude AI handles all automation** through intelligent conversation routing
- No need for rule-based automation
- Simpler to manage AI-driven automation than rule-based

**When to re-enable**:
- If you need complex routing logic that AI can't handle
- If you want deterministic automation (not AI-based)
- For compliance or audit requirements that need explicit rules
- If you want to automate actions without AI involvement

**How to re-enable**:
Uncomment lines 613-619 in `Sidebar.vue`

---

### 5. **Canned Responses** ❌

**Location**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (lines 632-638)

**What it does**:
- Pre-written message templates
- Quick responses for common questions
- Shortcuts for frequently used messages
- Team-wide response library

**Why hidden for MVP**:
- **Claude AI generates contextual responses** automatically
- No need for pre-written templates
- AI provides more natural, personalized responses

**When to re-enable**:
- If agents need to send manual messages frequently
- If you want consistent wording for legal/compliance messages
- For very specific technical responses that AI might get wrong
- If you want to speed up manual agent responses

**How to re-enable**:
Uncomment lines 632-638 in `Sidebar.vue`

---

## Features Kept Visible (Core MVP Requirements)

### ✅ **Inbox**
- View all incoming messages
- Essential for monitoring conversations

### ✅ **Conversations**
- All conversations view
- Mentions
- Unattended conversations
- Folders (custom views)
- Teams
- Channels (WhatsApp, Instagram, Facebook)
- Labels

### ✅ **Contacts**
- Customer database
- Contact details
- Conversation history
- Segments
- Tagged contacts

### ✅ **Companies**
- Business customer management

### ✅ **Reports**
- Overview reports
- Conversation reports
- CSAT (Customer Satisfaction) reports
- SLA reports
- Bot reports

### ✅ **Settings**
- Account settings
- Agents management
- Teams management
- Agent assignment
- Inboxes configuration
- Labels
- Custom attributes
- Agent Bots
- **Macros** (kept for quick actions)
- Integrations
- Audit logs
- Custom roles
- SLA management

---

## Implementation Details

### File Modified
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

### Approach
- Features are **commented out**, not deleted
- All code remains in the codebase
- Easy to re-enable by uncommenting
- Maintains compatibility with upstream Chatwoot updates

### Comments Format
```javascript
// HAPPSEA: [Feature Name] hidden for MVP - [Reason]
// {
//   ... commented code ...
// },
```

---

## Testing Checklist

After hiding features, verify:
- ✅ Chatwoot loads without errors
- ✅ Sidebar shows only intended features
- ✅ Settings menu shows only intended options
- ✅ No broken links or navigation issues
- ✅ All visible features work correctly
- ✅ Docker image builds successfully

---

## Future Considerations

### If Customer Wants Marketing Features
→ Re-enable **Campaigns** module

### If Customer Wants Self-Service Support
→ Re-enable **Help Center/Portals** module

### If Customer Wants Manual Agent Efficiency
→ Re-enable **Canned Responses**

### If Customer Wants Rule-Based Automation
→ Re-enable **Automation Rules**

### If Customer Wants Native AI Features
→ Re-enable **Captain AI** module

---

## Maintenance Notes

1. **Upstream Updates**: When merging from upstream Chatwoot, check if new features were added to the sidebar and decide if they should be hidden.

2. **Feature Requests**: Before building custom features, check if a hidden Chatwoot feature already provides the functionality.

3. **Performance**: If performance becomes an issue, consider true code-splitting instead of just hiding UI elements.

4. **Documentation**: Keep this document updated if you hide/unhide features.

---

## Contact

For questions about hidden features or to request re-enabling:
- Review this document first
- Check if the feature solves the requirement
- Uncomment the relevant section in `Sidebar.vue`
- Test thoroughly before deploying

---

**Last Updated**: February 4, 2026  
**Modified By**: Cascade AI  
**Chatwoot Version**: Fork based on upstream develop branch
