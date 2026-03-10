# API Contracts

_Last updated: [YYYY-MM-DD]_

## Base URL

- Local: `http://localhost:[PORT]`
- Production: `[URL]`

## Endpoints

### [Module Name]

| Method | Path | Description | Auth |
| ------ | ---- | ----------- | ---- |
| POST   | /[resource] | Create | [Yes/No] |
| GET    | /[resource] | List all | [Yes/No] |
| GET    | /[resource]/:id | Get by ID | [Yes/No] |
| PATCH  | /[resource]/:id | Update | [Yes/No] |
| DELETE | /[resource]/:id | Delete | [Yes/No] |

## Error Response Format

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request"
}
```
