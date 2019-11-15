export const allIssuablesSelected = (state) => {
  // WARNING: Because we are only keeping track of selected values
  // this works, we will need to rethink this if we start tracking
  // [id]: false for not selected values.
  return state.issuables.length === Object.keys(state.selection).length;
};

export const isSelectedIssuable = (state) => id => Boolean(state.selection[id]);
