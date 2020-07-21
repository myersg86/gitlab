export const createObjectBuilder = obj => {
  let newObj = obj;

  return {
    withPropValue(key, value) {
      const hasKey = key in obj;

      if (!hasKey) {
        throw new Error(
          `[mock_server] Cannot write property that does not exist on object '${key}'`,
        );
      }

      newObj = {
        ...newObj,
        [key]: value,
      };

      return this;
    },
    build() {
      return { ...newObj };
    },
  };
};

export const withProps = (obj, props) =>
  Object.entries(props)
    .reduce((builder, [key, value]) => builder.withPropValue(key, value), createObjectBuilder(obj))
    .build();

export const mapProps = (obj, map) =>
  Object.keys(map).reduce((acc, key) => {
    if (key in obj) {
      const newKey = map[key];
      const val = obj[key];

      return Object.assign(acc, { [newKey]: val });
    }
    return acc;
  }, {});
