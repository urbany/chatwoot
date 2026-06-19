import { frontendURL } from '../../../helper/URLHelper';
import KanbanView from './KanbanView.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.KANBAN,
  permissions: ['administrator', 'agent', 'custom_role'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/kanban'),
    component: KanbanView,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'kanban_dashboard_index',
        component: KanbanView,
        meta: commonMeta,
      },
    ],
  },
];
