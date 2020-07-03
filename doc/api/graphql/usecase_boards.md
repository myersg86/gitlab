# Identify issue boards with GraphQL

Given the advantages of GraphQL as described in the [GraphQL API](index.md), this page presents
a substantive example that you can copy and paste into your own instance of the [GraphiQL explorer](https://gitlab.com/-/graphql-explorer).

## Set up the GraphiQL explorer

The following procedure describes how you can use the GraphiQL explorer to identify
existing issue boards in the `gitlab-docs` documentation repository:

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

![GraphiQL explorer search for boards](img/graphql_usecase_boards_v13_2.png)

If you want to view one of these boards, take one of the numeric identifiers shown in the output. From the screenshot, the first identifier is `105011`. Navigate to the following URL, which includes the identifier:

```markdown
https://gitlab.com/gitlab-org/gitlab-docs/-/boards/105011
```

For more information on each attribute, see the [GraphQL API Resources](reference/index.md).
