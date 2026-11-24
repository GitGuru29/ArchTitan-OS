# Google sign-in for TITAN AI

The C++ `titan-ai` engine (and the Kitty <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> search
window that calls it) supports three ways to authorize Gemini and Google Search grounding:

| Method | How to enable | Notes |
|---|---|---|
| Gemini API key | `titan-ai setup` or `GEMINI_API_KEY` / `GOOGLE_API_KEY` | Easiest. Works for chat and Google Search grounding. |
| Sign in with Google | `titan-ai auth google` | OAuth authorization code + PKCE via a local browser callback. No API key needed. |
| gcloud ADC | `gcloud auth application-default login` | Used automatically if a `~/.config/gcloud/application_default_credentials.json` exists. |

Nothing is baked into the ISO. Tokens are written to
`$XDG_CONFIG_HOME/archtitan/titan-ai-google.json` (default `~/.config/archtitan/`)
with mode `0600`. If both a sign-in and an API key exist, the sign-in is used; set
`TITAN_AI_GOOGLE_AUTH=api_key` (or `oauth` / `adc`) to force one method.

## 1. Create your own OAuth client (one time)

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and select or create a project.
2. Enable **Generative Language API** for that project.
3. Go to **Google Auth platform → Audience**. Set user type to **External**, then add your own
   email under **Test users** (required while the app is unpublished).
4. Go to **Google Auth platform → Clients → Create Client**:
   - Application type: **Desktop app**
   - Name: e.g. `ArchTitan TITAN AI`
5. Copy the **Client ID** and, if shown, the **Client secret**.

The CLI requests only these scopes:

- `https://www.googleapis.com/auth/cloud-platform`
- `https://www.googleapis.com/auth/generative-language.retriever`

## 2. Give the client ID to TITAN AI

Either store it in your private config:

```sh
titan-ai config set google_oauth.client_id '123456789-abc.apps.googleusercontent.com'
titan-ai config set google_oauth.client_secret 'your-client-secret'   # optional
titan-ai config set google_oauth.project_id 'your-gcp-project-id'      # optional, for billing headers
```

or export it for the current shell:

```sh
export GOOGLE_CLIENT_ID='123456789-abc.apps.googleusercontent.com'
export GOOGLE_CLIENT_SECRET='your-client-secret'  # optional
export GOOGLE_CLOUD_PROJECT='your-gcp-project-id' # optional
```

## 3. Sign in

On a desktop session (opens the default browser and waits for the loopback callback):

```sh
titan-ai auth google
```

On a headless terminal / SSH session, use the device-code flow instead:

```sh
titan-ai auth google --device
# visit the printed URL and enter the printed code
```

You may see a "Google hasn't verified this app" warning — that is expected for a personal
OAuth client in testing mode. Choose **Advanced → Continue**.

Check the result with:

```sh
titan-ai status
```

Revoke and remove the local token with:

```sh
titan-ai auth logout
```

## 4. Use Google Search grounding

```sh
titan-ai search 'what changed in the latest Arch Linux kernel?'
titan-ai search --links 'ArchTitan OS documentation'
titan-ai -p gemini 'summarise this news topic'   # plain Gemini chat
```

Grounding uses the Gemini `google_search` tool. The answer includes `[n]` citation markers and
a numbered source list. The Kitty shortcut uses exactly the same path: press
<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd>, type your query at `search>`, and the answer with
source links appears in the new window. Note that Google bills search grounding requests per
query on newer Gemini models; see the Gemini API pricing page for current limits.

## Troubleshooting

- **`invalid_client` / redirect URI mismatch** — create a *Desktop app* client; Google permits
  loopback redirects on any localhost port for that client type.
- **`access_denied`** — the signed-in account must be listed under **Test users**.
- **`403 Generative Language API not enabled`** — enable the API in the same project as the
  OAuth client and set `GOOGLE_CLOUD_PROJECT` if the token's project is ambiguous.
- **Token expired errors** — run `titan-ai auth google` again. Tokens refresh automatically when
  a refresh token is available.
