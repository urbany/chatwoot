import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from 'dashboard/store/mutation-types';
import FunnelsAPI from '../api/funnels';

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
  getFunnels: _state => {
    return _state.records;
  },
  getFunnelById: _state => id => {
    return _state.records.find(record => record.id === Number(id)) || null;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isFetching: true });
    try {
      const response = await FunnelsAPI.get();
      commit(types.SET_KANBAN_FUNNELS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, funnelObj) => {
    commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isCreating: true });
    try {
      const response = await FunnelsAPI.create(funnelObj);
      commit(types.ADD_KANBAN_FUNNEL, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      const response = await FunnelsAPI.update(id, updateObj);
      commit(types.EDIT_KANBAN_FUNNEL, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isDeleting: true });
    try {
      await FunnelsAPI.delete(id);
      commit(types.DELETE_KANBAN_FUNNEL, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_FUNNELS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_KANBAN_FUNNELS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_KANBAN_FUNNELS]: MutationHelpers.set,
  [types.ADD_KANBAN_FUNNEL]: MutationHelpers.create,
  [types.EDIT_KANBAN_FUNNEL]: MutationHelpers.update,
  [types.DELETE_KANBAN_FUNNEL]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
