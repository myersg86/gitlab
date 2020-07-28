export const currentTreeLoaded = state => {
  const tree = state.trees[`${state.currentProjectId}/${state.currentBranchId}`];
  if (!tree) return false;
  return !tree.loading;
};

export * from '~/ide/stores/getters';
