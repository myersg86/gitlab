# GraphQL Use cases

Given the advantages of GraphQL as described in the [GraphQL API](index.md), this page presents
a substantive example that you can copy and paste into your own instance of the [GraphiQL explorer](https://gitlab.com/-/graphql-explorer).

## Use case: identify issue boards

The following procedure describes how you can use the GraphiQL explorer to identify
existing issue boards in the `gitlab-docs` documentation repository.

1. Copy the following code excerpt:

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

1. Open the GraphiQL explorer tool in the following URL: `https://gitlab.com/-/graphql-explorer`.
1. Paste the `query` listed above into the left window of your GraphiQL explorer tool.
1. Click Play <should include SVG of the play icon> to get the result shown here:

![GraphiQL explorer search for boards](img/graphql_usecase_boards_v13_0.png)

The query includes:

| Attribute    | Description              |
|--------------|--------------------------|
| `forksCount` | Number of forks          |
| `wikiSize`   | Size of wiki pages       |
| `boards`     | Identifier of each board |
| `name`       | Name of each board       |

You can append the identifier of each board (`boards`) to the following URL:
  `https://gitlab.com/gitlab-org/gitlab-docs/-/boards/`.

For more information on each attribute, see the [GraphQL API Resources](reference/index.md).
