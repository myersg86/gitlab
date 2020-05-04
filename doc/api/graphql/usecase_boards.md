# GraphQL Use cases

Given the advantages of GraphQL as described in the [GraphQL API](index.md), we expect readers
to look for substantive examples to copy and paste into their own instances of the [GraphiQL explorer](https://gitlab.com/-/graphql-explorer).

## Use case: identify issue boards

The following procedure describes how you can use the GraphiQL explorer to identify
existing issue boards in the `gitlab-docs` documentation repository.

```graphql
query {
  project(fullPath: "gitlab-org/gitlab-docs") {
    name
    forksCount
    statistics {
      wikiSize
    }
    issuesEnabled
    boards {
      edges {
        node {
          id
          name
        }
      }
    }
  }
}
```

You can copy the `query` listed above into the left-hand window of your GraphiQL explorer tool, and click the Play button to get the result shown here:

![GraphiQL explorer search for boards](img/graphql_usecase_boards_v13_0.png)

The query includes:

- Number of forks (`forksCount`).
- Size of wiki pages (`wikiSize`).
- The identifier of each board (`boards`), which you can append to the following URL:
  `https://gitlab.com/gitlab-org/gitlab-docs/-/boards/`.
- The name of each board (`name`).

For details of each of these properties, see the [GraphQL API Resources](reference/index.md).
