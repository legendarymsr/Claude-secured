# 07 — Network & API Security

Claude Code sends data to Anthropic's API to generate responses. Understanding exactly what leaves your machine — and how to control it — is essential for compliance-sensitive environments.

## What is sent to Anthropic

Every API call includes:
- Your prompts
- File contents that Claude reads (via `Read` tool)
- Command output (via `Bash` tool)
- Tool results from MCP servers
- Web page contents (via `WebFetch`)

This data is encrypted in transit with TLS 1.2+.

**Sent only if you opt in:**
- Session transcripts (via "How is Claude doing?" survey prompts)
- Feedback content (via `/feedback` command — you choose whether to include the transcript)

## Data retention options

| Option | What it means |
|--------|--------------|
| Standard | Anthropic retains API inputs/outputs per their standard privacy policy |
| Zero Data Retention (ZDR) | No data stored server-side after the API call completes |

ZDR requires an enterprise agreement with Anthropic. Once enabled, it applies to all API calls from your account.

## Telemetry and how to disable it

Claude Code sends operational metrics (latency, error rates, usage patterns — **not code**) to telemetry services. You can opt out:

```bash
# Environment variables
export DISABLE_TELEMETRY=1            # Stop operational metrics (Statsig)
export DISABLE_ERROR_REPORTING=1      # Stop error logs (Sentry)
export DISABLE_FEEDBACK_COMMAND=1     # Remove the /feedback command
```

Or in `settings.json`:

```json
{
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  }
}
```

## WebFetch domain safety check

Before fetching any URL, Claude Code sends the **hostname only** (not the full URL or any path/query parameters) to `api.anthropic.com` to check against a safety blocklist. The result is cached for 5 minutes.

If a domain is blocked and you believe it shouldn't be, you can allowlist it:

```json
{
  "permissions": {
    "allow": ["WebFetch(domain:internal.example.com)"]
  }
}
```

Or disable the preflight check entirely (not recommended):

```json
{
  "skipWebFetchPreflight": true
}
```

## Cloud execution (claude.ai/code)

When using Claude Code via the web interface:

- Code runs in **isolated Anthropic-managed VMs**, separate from your local machine
- Your repository is cloned into the VM for the session
- GitHub authentication is handled via a secure proxy — your credentials never enter the VM directly
- Network traffic routes through a security proxy with audit logging
- VMs are automatically destroyed at the end of the session

This provides stronger isolation than running Claude Code locally, at the cost of your code leaving your infrastructure.

## Using Claude Code with cloud providers

If you access Claude models via Amazon Bedrock or Google Vertex AI, data handling follows those providers' policies:

| Provider | Encryption at rest | Customer-managed keys |
|----------|------------------|----------------------|
| Anthropic direct | AES-256 (Anthropic-managed) | ZDR option |
| Amazon Bedrock | AWS-managed or KMS | Yes (CMEK) |
| Google Vertex AI | Google-managed | Yes (CMEK) |

## Network proxy configuration

For environments that route all traffic through a corporate proxy:

```json
{
  "env": {
    "HTTPS_PROXY": "https://proxy.corp.example.com:8080",
    "NO_PROXY": "localhost,127.0.0.1"
  }
}
```

## See also

- [docs/03-settings.md](03-settings.md) — Setting environment variables via settings.json
- [docs/08-best-practices.md](08-best-practices.md) — Enterprise network configuration guidance
