import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from 'dashboard/store/mutation-types';
import KanbanItemsAPI from '../api/kanbanItems';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getItems: _state => {
    return _state.records;
  },
  getItemsByStage: _state => stage => {
    return _state.records
      .filter(record => record.funnel_stage === stage)
      .sort((a, b) => a.position - b.position);
  },
  getItemById: _state => id => {
    return _state.records.find(record => record.id === Number(id)) || null;
  },
};

export const actions = {
  get: async ({ commit }, { funnelId, stage = null }) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isFetching: true });
    try {
      const response = await KanbanItemsAPI.list(funnelId, stage);
      commit(types.SET_KANBAN_ITEMS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, itemObj) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isCreating: true });
    try {
      const response = await KanbanItemsAPI.create(itemObj);
      commit(types.ADD_KANBAN_ITEM, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: true });
    try {
      const response = await KanbanItemsAPI.update(id, updateObj);
      commit(types.EDIT_KANBAN_ITEM, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isDeleting: true });
    try {
      await KanbanItemsAPI.delete(id);
      commit(types.DELETE_KANBAN_ITEM, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isDeleting: false });
    }
  },
  move: async ({ commit }, { id, funnelStage, position }) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: true });
    try {
      const response = await KanbanItemsAPI.move(id, funnelStage, position);
      commit(types.EDIT_KANBAN_ITEM, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: false });
    }
  },
  reorder: async ({ commit }, { id, position }) => {
    commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: true });
    try {
      const response = await KanbanItemsAPI.reorder(id, position);
      commit(types.EDIT_KANBAN_ITEM, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_ITEMS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_KANBAN_ITEMS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_KANBAN_ITEMS]: MutationHelpers.set,
  [types.ADD_KANBAN_ITEM]: MutationHelpers.create,
  [types.EDIT_KANBAN_ITEM]: MutationHelpers.update,
  [types.DELETE_KANBAN_ITEM]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
