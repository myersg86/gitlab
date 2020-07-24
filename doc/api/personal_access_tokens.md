# Personal access tokens API

You can read more about [personal access tokens](../user/profile/personal_access_tokens.md#personal-access-tokens).

## List personal access tokens

Get a list of personal access tokens.

```plaintext
GET /personal_access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `user_id` | integer/string | no | The ID of the user to filter by |

NOTE: **Note:**
Administrators can use the `user_id` parameter to filter by a user. Non-administrators cannot filter by any user except themselves (this is also the default behavior, when omitting the parameter entirely).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens"
```

```json
[  
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
        "scopes": [
            "api"
        ],
        "active": true,
        "user_id": 24,
        "expires_at": null
    }
]
```
