export const buildCaptainMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Captain',
  icon: 'i-woot-captain',
  label: t('SIDEBAR.CAPTAIN'),
  activeOn: ['captain_assistants_create_index'],
  children: [
    {
      name: 'FAQs',
      label: t('SIDEBAR.CAPTAIN_RESPONSES'),
      activeOn: [
        'captain_assistants_responses_index',
        'captain_assistants_responses_pending',
      ],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_responses_index',
      }),
    },
    {
      name: 'Documents',
      label: t('SIDEBAR.CAPTAIN_DOCUMENTS'),
      activeOn: ['captain_assistants_documents_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_documents_index',
      }),
    },
    {
      name: 'Scenarios',
      label: t('SIDEBAR.CAPTAIN_SCENARIOS'),
      activeOn: ['captain_assistants_scenarios_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_scenarios_index',
      }),
    },
    {
      name: 'Playground',
      label: t('SIDEBAR.CAPTAIN_PLAYGROUND'),
      activeOn: ['captain_assistants_playground_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_playground_index',
      }),
    },
    {
      name: 'Inboxes',
      label: t('SIDEBAR.CAPTAIN_INBOXES'),
      activeOn: ['captain_assistants_inboxes_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_inboxes_index',
      }),
    },
    {
      name: 'Tools',
      label: t('SIDEBAR.CAPTAIN_TOOLS'),
      activeOn: ['captain_tools_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_tools_index',
      }),
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.CAPTAIN_SETTINGS'),
      activeOn: [
        'captain_assistants_settings_index',
        'captain_assistants_guidelines_index',
        'captain_assistants_guardrails_index',
      ],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_settings_index',
      }),
    },
  ],
});

export const buildCompaniesMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Companies',
  label: t('SIDEBAR.COMPANIES'),
  icon: 'i-lucide-building-2',
  children: [
    {
      name: 'All Companies',
      label: t('SIDEBAR.ALL_COMPANIES'),
      to: accountScopedRoute(
        'companies_dashboard_index',
        {},
        { page: 1, search: undefined }
      ),
      activeOn: ['companies_dashboard_index'],
    },
  ],
});

export const buildReportsMenuItem = ({
  t,
  accountScopedRoute,
  reportRoutes,
}) => ({
  name: 'Reports',
  label: t('SIDEBAR.REPORTS'),
  icon: 'i-lucide-chart-spline',
  children: [
    {
      name: 'Report Overview',
      label: t('SIDEBAR.REPORTS_OVERVIEW'),
      to: accountScopedRoute('account_overview_reports'),
    },
    {
      name: 'Report Conversation',
      label: t('SIDEBAR.REPORTS_CONVERSATION'),
      to: accountScopedRoute('conversation_reports'),
    },
    ...reportRoutes,
    {
      name: 'Reports CSAT',
      label: t('SIDEBAR.CSAT'),
      to: accountScopedRoute('csat_reports'),
    },
    {
      name: 'Reports SLA',
      label: t('SIDEBAR.REPORTS_SLA'),
      to: accountScopedRoute('sla_reports'),
    },
    {
      name: 'Reports Bot',
      label: t('SIDEBAR.REPORTS_BOT'),
      to: accountScopedRoute('bot_reports'),
    },
  ],
});

export const buildCampaignsMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Campaigns',
  label: t('SIDEBAR.CAMPAIGNS'),
  icon: 'i-lucide-megaphone',
  children: [
    {
      name: 'Live chat',
      label: t('SIDEBAR.LIVE_CHAT'),
      to: accountScopedRoute('campaigns_livechat_index'),
    },
    {
      name: 'SMS',
      label: t('SIDEBAR.SMS'),
      to: accountScopedRoute('campaigns_sms_index'),
    },
    {
      name: 'WhatsApp',
      label: t('SIDEBAR.WHATSAPP'),
      to: accountScopedRoute('campaigns_whatsapp_index'),
    },
  ],
});

export const buildHelpCenterMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Portals',
  label: t('SIDEBAR.HELP_CENTER.TITLE'),
  icon: 'i-lucide-library-big',
  children: [
    {
      name: 'Articles',
      label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
      activeOn: [
        'portals_articles_index',
        'portals_articles_new',
        'portals_articles_edit',
      ],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_articles_index',
      }),
    },
    {
      name: 'Categories',
      label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
      activeOn: [
        'portals_categories_index',
        'portals_categories_articles_index',
        'portals_categories_articles_edit',
      ],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_categories_index',
      }),
    },
    {
      name: 'Locales',
      label: t('SIDEBAR.HELP_CENTER.LOCALES'),
      activeOn: ['portals_locales_index'],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_locales_index',
      }),
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
      activeOn: ['portals_settings_index'],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_settings_index',
      }),
    },
  ],
});

export const buildCaptainSettingsMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Settings Captain',
  label: t('SIDEBAR.CAPTAIN_AI'),
  icon: 'i-woot-captain',
  to: accountScopedRoute('captain_settings_index'),
});

export const buildAutomationSettingsMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Settings Automation',
  label: t('SIDEBAR.AUTOMATION'),
  icon: 'i-lucide-repeat',
  to: accountScopedRoute('automation_list'),
});

export const buildCannedResponsesSettingsMenuItem = ({
  t,
  accountScopedRoute,
}) => ({
  name: 'Settings Canned Responses',
  label: t('SIDEBAR.CANNED_RESPONSES'),
  icon: 'i-lucide-message-square-quote',
  to: accountScopedRoute('canned_list'),
});

export const buildBillingSettingsMenuItem = ({ t, accountScopedRoute }) => ({
  name: 'Settings Billing',
  label: t('SIDEBAR.BILLING'),
  icon: 'i-lucide-credit-card',
  to: accountScopedRoute('billing_settings_index'),
});
