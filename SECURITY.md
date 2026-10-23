# Security

This repository is a **sanitized** public version of a delivered client project.

Never commit: `.env`, database backups, OAuth client files, n8n credential exports,
real Drive/Sheets IDs, owner names, tax IDs, emails or bank data.

Before publishing any workflow export run `python tools/sanitize_workflows.py` and review the
diff. If you find a leaked secret, rotate it first, then remove it from history.
