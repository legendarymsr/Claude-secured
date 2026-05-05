# 07 — Network & API Security

Claude Code sends data to Anthropic's API to generate responses. Here's exactly what leaves your machine and how to control it.

---

## What gets sent to Anthropic

Every API call includes:
- Your prompts
- File contents Claude reads
- Shell command output
- MCP tool results
- Web page contents (via WebFetch)

All traffic is encrypted in transit with **TLS 1.2+**.

---

## What does NOT get sent (unless you opt in)

- Session transcripts — only if you say yes to a quality survey prompt
- Feedback content — only if you use `/feedback` and choose to include the transcript

---

## Telemetry opt-outs

```json
{
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  }
}
```

`DISABLE_TELEMETRY` stops operational metrics (latency, error rates — no code is included).  
`DISABLE_ERROR_REPORTING` stops error logs sent to Sentry.

<details>
<summary>📖 Full data flow breakdown</summary>

### What Anthropic receives per API call

| Data | Sent? | Notes |
|------|-------|-------|
| Your prompt | Always | Encrypted in transit |
| File contents Claude reads | Always (when read) | Only files Claude actually opens |
| Bash command output | Always (when run) | stdout/stderr of commands |
| MCP tool results | Always (when called) | Whatever the server returns |
| WebFetch page content | Always (when fetched) | Full page text |
| Session transcript | Only if you opt in | Via survey or /feedback |
| Error logs | Only if enabled | Via Sentry, no code content |
| Operational metrics | By default | Latency, error rates — no code |

### At-rest encryption by provider

| Provider | Encryption | Customer-managed keys |
|----------|-----------|----------------------|
| Anthropic direct | AES-256 (Anthropic-managed) | Via Zero Data Retention |
| Amazon Bedrock | AWS-managed or KMS | Yes (CMEK) |
| Google Vertex AI | Google-managed | Yes (CMEK) |

</details>

<details>
<summary>📖 Zero Data Retention (ZDR)</summary>

ZDR is an enterprise option where API inputs and outputs are not stored server-side after the request completes. Available via enterprise agreement with Anthropic.

With ZDR:
- Prompts, file contents, and outputs are processed in memory only
- Nothing persists after the API response is returned
- Useful for compliance requirements (HIPAA, GDPR data minimization, etc.)

Without ZDR, standard Anthropic data retention policies apply. Check the Anthropic privacy policy for current retention periods.

To enable ZDR: contact Anthropic sales. Once enabled, it applies to all API calls from your account.

</details>

<details>
<summary>📖 WebFetch domain safety check</summary>

Before fetching any URL, Claude Code sends the **hostname only** (not the full URL, path, or query parameters) to `api.anthropic.com` to check against a safety blocklist. The result is cached for 5 minutes.

If a domain is blocked and you believe it shouldn't be, you can allowlist it:
```json
{ "permissions": { "allow": ["WebFetch(domain:internal.example.com)"] } }
```

To disable the preflight check entirely (not recommended):
```json
{ "skipWebFetchPreflight": true }
```

</details>

<details>
<summary>📖 Cloud execution (claude.ai/code)</summary>

When running Claude Code via the web interface at claude.ai/code:

- Code runs in **isolated Anthropic-managed VMs**, separate from your local machine
- Your repository is cloned into the VM for the session
- GitHub authentication is handled via a secure proxy — credentials never enter the VM directly
- Network traffic routes through a security proxy with audit logging
- VMs are destroyed at the end of the session — nothing persists

This provides stronger isolation than local execution, at the cost of your code leaving your own infrastructure.

</details>

<details>
<summary>📖 Corporate proxy configuration</summary>

For environments that route traffic through a corporate proxy:

```json
{
  "env": {
    "HTTPS_PROXY": "https://proxy.corp.example.com:8080",
    "NO_PROXY": "localhost,127.0.0.1,internal.example.com"
  }
}
```

Claude Code respects standard `HTTPS_PROXY` / `NO_PROXY` environment variables.

</details>

---

## See also

- [docs/03-settings.md](03-settings.md) — Setting env vars in settings.json
- [docs/12-secrets-management.md](12-secrets-management.md) — Keeping credentials out of API calls
- [docs/13-ci-cd-guide.md](13-ci-cd-guide.md) — Network controls in CI
