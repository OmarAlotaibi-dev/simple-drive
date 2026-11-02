
# Simple Drive

Simple Drive is a Ruby on Rails API for storing and retrieving arbitrary binary data using unique string identifiers.

The application stores blob metadata in SQLite and supports three configurable storage backends:

- Local filesystem
- Database
- Amazon S3-compatible object storage

The S3 integration uses Ruby's built-in HTTP client and AWS Signature Version 4 signing, without an S3 SDK.

## Requirements

- Ruby 4.0
- Ruby on Rails 8.1
- SQLite3
- Bundler
- An S3-compatible service when using the S3 backend

## Setup

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
ruby bin/rails db:prepare
```

Configure a bearer token using the `API_TOKEN` environment variable.

Start the server:

```bash
ruby bin/rails server
```

The API runs at `http://localhost:3000` by default.

## Storage Configuration

Select the storage backend using the `STORAGE_BACKEND` environment variable.

### Local Filesystem

```text
STORAGE_BACKEND=local
STORAGE_DIR=storage/blobs
```

`STORAGE_DIR` is optional. By default, files are stored in the application's `storage/blobs` directory.

### Database

```text
STORAGE_BACKEND=database
```

Binary data is stored in the `stored_blobs` table, separately from the `blob_metadata` table.

### S3-Compatible Storage

```text
STORAGE_BACKEND=s3
S3_ENDPOINT=http://127.0.0.1:9000
S3_BUCKET=your-bucket
S3_REGION=us-east-1
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
```

The S3 bucket must exist before uploading blobs.

For local testing, an S3-compatible service such as MinIO can be used.

Do not commit access keys, bearer tokens, or other secrets to version control.

## Authentication

All API requests require a bearer token:

```http
Authorization: Bearer YOUR_API_TOKEN
```

The expected token is configured using the `API_TOKEN` environment variable.

Requests with missing or incorrect tokens receive HTTP `401 Unauthorized`.

## API Endpoints

### POST /v1/blobs

Stores Base64-encoded binary data under a unique identifier.

Request:

```json
{
  "id": "documents/example.bin",
  "data": "SGVsbG8="
}
```

Successful response: HTTP `201 Created`.

The response includes the blob identifier, its size in bytes as a string, and its creation timestamp.

### GET /v1/blobs/{id}

Retrieves a previously stored blob.

Example:

```text
GET /v1/blobs/documents/example.bin
```

Successful response: HTTP `200 OK`.

```json
{
  "id": "documents/example.bin",
  "data": "SGVsbG8=",
  "size": "5",
  "created_at": "2026-11-02T12:00:00Z"
}
```

The `created_at` value above is illustrative.

Identifiers may contain forward slashes.

## Error Responses

| Status | Meaning |
| --- | --- |
| 400 | Invalid request data or Base64 encoding |
| 401 | Missing or invalid bearer token |
| 404 | Blob not found |
| 409 | Blob identifier already exists |
| 503 | Storage connection unavailable |

Error responses use JSON.

## Example Using PowerShell

Set the API token:

```powershell
$env:API_TOKEN = "your-local-test-token"
```

Create a blob:

```powershell
$body = @{
  id = "example-1"
  data = [Convert]::ToBase64String(
    [System.Text.Encoding]::UTF8.GetBytes("Hello")
  )
} | ConvertTo-Json -Compress

Invoke-RestMethod `
  -Uri "http://localhost:3000/v1/blobs" `
  -Method Post `
  -Headers @{ Authorization = "Bearer $env:API_TOKEN" } `
  -ContentType "application/json" `
  -Body $body
```

Retrieve the blob:

```powershell
Invoke-RestMethod `
  -Uri "http://localhost:3000/v1/blobs/example-1" `
  -Method Get `
  -Headers @{ Authorization = "Bearer $env:API_TOKEN" }
```

## Data Organization

Blob metadata is stored in the `blob_metadata` table, including:

- Blob identifier
- Size in bytes
- Storage backend
- Creation timestamp

Binary content is stored using the selected backend.

The backend used when a blob is created is recorded in its metadata, allowing the application to retrieve it even if the default backend changes.

## FTP Storage (Bonus)

In addition to the three required storage backends, Simple Drive supports FTP storage.

Configure the following environment variables:

```text
STORAGE_BACKEND=ftp
FTP_HOST=127.0.0.1
FTP_PORT=2121
FTP_USERNAME=your-ftp-username
FTP_PASSWORD=your-ftp-password
FTP_DIRECTORY=/
```

An accessible FTP server with read and write permissions is required.

The FTP backend uses Ruby's `net-ftp` library to upload and retrieve binary data.

Blob identifiers are mapped to SHA-256 filenames, allowing identifiers containing forward slashes to be stored safely.

The FTP backend was manually tested with FileZilla Server.

Plain FTP does not encrypt credentials or transferred data. Use it only in a trusted local testing environment.

## Automated Tests

The project includes automated tests for:

- API authentication and blob creation/retrieval
- Invalid Base64 input
- Duplicate blob identifiers
- Missing blobs
- Binary data and identifiers containing slashes
- Local filesystem storage
- Database storage
- S3-compatible storage with mocked HTTP requests
- FTP storage with a mocked FTP connection

Run the complete test suite:

```bash
ruby bin/rails test
```

Latest verified result:

```text
16 runs, 32 assertions, 0 failures, 0 errors, 0 skips
```

The S3 and FTP automated tests use mocked connections and do not require running external storage servers.
