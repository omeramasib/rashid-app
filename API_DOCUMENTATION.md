# Rashed Backend API Documentation

## Base URL
- Local: `http://localhost:8000`
- Swagger UI: `GET /docs`
- ReDoc: `GET /redoc`
- Health: `GET /health`

## Authentication
For protected endpoints, send:
- `Authorization: Bearer <jwt_token>`

JWT notes:
- JWT `sub` is always `user.id` (UUID string).
- Auth routes are under `/auth/*`.
- Product routes are under `/api/v1/*`.

## Standard Response Shape
Most endpoints use:

```json
{
  "status": "success",
  "message": "...",
  "data": {}
}
```

---

## Auth APIs (`/auth/*`)

### Login with Email
- **POST** `/auth/login/email`

Request:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "status": "success",
  "token": "jwt_token_here",
  "user": {
    "id": "uuid",
    "name": "User Name",
    "email": "user@example.com"
  }
}
```

### Register with Email
- **POST** `/auth/register/email`

Request:
```json
{
  "name": "User Name",
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "status": "success",
  "message": "Account created successfully",
  "user_id": "uuid"
}
```

### Login with LinkedIn
- **POST** `/auth/login/linkedin`

Request:
```json
{
  "linkedin_token": "linkedin_access_token"
}
```

### Register with LinkedIn
- **POST** `/auth/register/linkedin`

Request:
```json
{
  "linkedin_token": "linkedin_access_token"
}
```

### Forgot Password
- **POST** `/auth/forgot-password`

Request:
```json
{
  "email": "user@example.com"
}
```

### Reset Password
- **POST** `/auth/reset-password`

Request:
```json
{
  "token": "reset_token",
  "new_password": "newPassword123"
}
```

### Change Password
- **POST** `/auth/change-password`
- **Auth required**

Request:
```json
{
  "current_password": "oldPassword",
  "new_password": "newPassword123"
}
```

### Logout
- **POST** `/auth/logout`
- **Auth required**

Response:
```json
{
  "status": "success",
  "message": "Logged out successfully"
}
```

### Current User
- **GET** `/auth/me`
- **Auth required**

Response:
```json
{
  "id": "uuid",
  "name": "User Name",
  "email": "user@example.com"
}
```

---

## LinkedIn APIs (`/api/v1/linkedin/*`)

> Backend does **not** perform OAuth code exchange. Mobile app (Clerk) provides access token, backend verifies and stores it.

### Connect LinkedIn
- **POST** `/api/v1/linkedin/connect`
- **Auth required**

Request:
```json
{
  "linkedin_access_token": "linkedin_access_token"
}
```

Behavior:
- Verifies token with:
  - `GET https://api.linkedin.com/v2/me`
  - `GET https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))`
- Upserts `linkedin_accounts` for current user.

Response:
```json
{
  "status": "success",
  "message": "LinkedIn account connected",
  "data": {
    "linkedin_profile_id": "abc123",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Disconnect LinkedIn
- **POST** `/api/v1/linkedin/disconnect`
- **Auth required**

Response:
```json
{
  "status": "success",
  "message": "LinkedIn account disconnected"
}
```

---

## Home APIs (`/api/v1/home/*`)

### Share Last Interview Result
- **POST** `/api/v1/home/share-last-interview-result`
- **Auth required**

Request:
```json
{
  "caption": "Optional custom post text"
}
```

Behavior:
- Loads latest interview simulation for current user
- Requires active LinkedIn connection
- Posts to `POST https://api.linkedin.com/v2/ugcPosts`
- Sends `X-Restli-Protocol-Version: 2.0.0`
- Stores share audit in `share_activities`

Success response:
```json
{
  "status": "success",
  "message": "Interview result shared on LinkedIn",
  "data": {
    "post_url": "https://www.linkedin.com/feed/update/...",
    "post_urn": "urn:li:share:..."
  }
}
```

Possible errors:
- `401`: `"LinkedIn connection expired. Please reconnect via Clerk."`
- `400`: no LinkedIn account connected
- `404`: no simulation found

---

## CV APIs (`/api/v1/cv/*`)

### Upload CV
- **POST** `/api/v1/cv/upload`
- **Auth required**
- **multipart/form-data** with `file`

Supported:
- `.pdf`
- `.docx`

Response:
```json
{
  "status": "success",
  "message": "CV uploaded successfully",
  "data": {
    "cv_id": "uuid",
    "file_url": "https://..."
  }
}
```

### Analyze CV
- **POST** `/api/v1/cv/analyze`
- **Auth required**

Request:
```json
{
  "cv_id": "uuid"
}
```

Behavior:
- Downloads CV file URL
- Extracts text from PDF/DOCX
- Runs synchronous Gemini analysis with strict JSON
- Tracks execution in `ai_jobs`
- Updates CV extracted fields + merges profile skills

Response:
```json
{
  "status": "success",
  "message": "CV analyzed successfully",
  "data": {
    "full_name": "Jane Smith",
    "job_titles": ["Software Engineer"],
    "skills": ["Python", "FastAPI"]
  }
}
```

### Update Skills
- **PUT** `/api/v1/cv/skills/update-skills`
- **Auth required**

Request:
```json
{
  "skills": ["Python", "SQL", "Docker"]
}
```

### Delete Skill
- **DELETE** `/api/v1/cv/skills/delete`
- **Auth required**

Request:
```json
{
  "skill": "SQL"
}
```

---

## Interview APIs (`/api/v1/interview/*`)

### Start Interview by Job
- **POST** `/api/v1/interview/start/by-job`
- **Auth required**

Request:
```json
{
  "job_field": "Software Engineering",
  "interview_type": "technical",
  "difficulty": "medium",
  "language": "English",
  "simulation_type": "text",
  "num_questions": 5
}
```

### Start Interview by Job Description
- **POST** `/api/v1/interview/start/by-job-description`
- **Auth required**

Request:
```json
{
  "job_description": "Senior backend role...",
  "interview_type": "technical",
  "difficulty": "hard",
  "language": "English",
  "simulation_type": "audio",
  "num_questions": 5
}
```

Shared behavior for start endpoints:
- Creates `interview_settings` and `interview_simulations`
- Generates questions via Gemini (strict JSON)
- Persists `interview_questions`
- For `simulation_type=audio`, generates TTS and uploads audio to S3

Start response:
```json
{
  "status": "success",
  "message": "Interview started",
  "data": {
    "simulation_id": "uuid",
    "interview_setting_id": "uuid",
    "questions": [
      {
        "id": "uuid",
        "question_text": "What is polymorphism?",
        "audio_url": null
      }
    ]
  }
}
```

### Submit Answer / Skip
- **POST** `/api/v1/interview/answer/submit`
- **Auth required**

Answer request:
```json
{
  "question_id": "uuid",
  "skipped": false,
  "answer_text": "Your answer text"
}
```

Skip request:
```json
{
  "question_id": "uuid",
  "skipped": true
}
```

Behavior:
- Ownership validation
- Skip sets `is_skipped` + `skipped_at`
- Non-skip evaluates using Gemini and stores score/strengths/weaknesses/suggested_answer

### Finish Interview
- **POST** `/api/v1/interview/finish`
- **Auth required**

Request:
```json
{
  "simulation_id": "uuid"
}
```

Behavior:
- Computes final score excluding skipped questions
- Updates `interview_simulations`
- Updates/creates `performance_reports`

### Interview Report
- **GET** `/api/v1/interview/report?simulation_id=<uuid>`
- **Auth required**

### Simulations History
- **GET** `/api/v1/interview/simulations`
- **Auth required**

---

## Error Conventions
- `400`: validation or business rule violation
- `401`: authentication failure or expired LinkedIn connection
- `403`: ownership/access violation
- `404`: entity not found
- `502`: upstream external API/storage/AI failure
