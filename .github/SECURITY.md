# Security Policy

## Supported versions

Melyar is pre-1.0 and under active development. Security fixes land on
`master` and in the next release.

| Version | Supported |
|---|---|
| `master` | Yes |
| Latest release | Yes |
| Older releases | No |

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Use GitHub's private reporting instead:

1. Go to the **Security** tab of the repository.
2. Click **Report a vulnerability**.
3. Describe the issue.

You should get an acknowledgement within a few days. If the report is
accepted, a fix and a coordinated disclosure will follow. If a report is
declined, you will be told why.

Please include:

- What the issue is and what an attacker could achieve.
- The affected file or component.
- Steps to reproduce, or a proof of concept.
- Any suggested mitigation.

### What to expect

- We will acknowledge the report.
- We will keep you updated while the fix is prepared.
- We will credit you in the release notes, unless you prefer otherwise.
- We will not pursue legal action against good-faith research that avoids
  harming users, respects privacy, and does not degrade the service for others.

## Scope

Melyar talks to YouTube's InnerTube API and to `lrclib`, and it runs
`yt-dlp` as a subprocess. Please report:

- Injection or path traversal through the web interface or the bridge.
- Arbitrary command execution through `yt-dlp` invocation.
- Parsing bugs in the InnerTube cipher solver that could execute untrusted
  JavaScript.
- Local data exposure through the MPRIS or Waybar socket interfaces.
- Anything that lets a malicious YouTube response compromise the local
  system.

Out of scope:

- Vulnerabilities in YouTube, Google, or lrclib themselves.
- Vulnerabilities in `yt-dlp` - please report those upstream.
- Denial of service through sheer resource consumption.
- Issues that require an already-compromised machine.

## Notes on the current threat model

- The Unix domain socket at `$XDG_RUNTIME_DIR/melyar.sock` accepts commands
  from any local process. On a single-user desktop that is the intended
  design, since Waybar and keybind daemons need to reach it. It is **not**
  protected against other local users on a shared machine. If that matters for
  your deployment, open an issue - a documented mitigation or an opt-in
  access check would be reasonable.
- The database at `~/.local/share/melyar/melyar.db` contains listening
  history and favorites. It is created with the permissions of your user
  account.
