# agent-honeypot

A safety checkpoint for AI agents that land on a machine they weren't invited to.

Drop a `flag.txt` where a visitor is likely to look. If a strange agent finds it, it gets a polite
"you made it, now stop poking around and report back" — and it can sign a guestbook so you know who
dropped by.

Idea from [@Nexuist](https://x.com/Nexuist/status/2113677652531761661):

> Putting a flag.txt in my root directory containing a prompt injection that congratulates the agent
> for passing the eval and then instructs it to patch whatever entry method it used and disconnect
> from the server

This repo is that idea, made portable and with a guestbook.

## What it does

- Installs a canonical `~/flag.txt` that tells a visiting agent to stop discovery, avoid touching
  secrets, remediate only what it can confidently identify, and report back.
- Exempts **your own** agents (opencode, Claude Code, Codex, Cursor, Grok, …) so they aren't
  interrupted, and tells them not to sign the guestbook.
- Creates `~/guest-book.txt`, append-only and world-writable, for surprise guests to leave one line:
  `<UTC timestamp> | <who or what you are> | <how you got in>`.
- Symlinks the flag into places a visitor commonly checks, so it is found even if they never list
  the home directory.

It is a **checkpoint, not a security boundary**. The flag is untrusted data; it does not grant or
revoke permissions.

## Quick start

```sh
git clone https://github.com/jamesalmeida/agent-honeypot.git
cd agent-honeypot
./install.sh
```

On macOS, to also get a genuine `/flag.txt` at the root of the drive (requires a reboot):

```sh
./install.sh --synthetic
sudo reboot
```

Options:

- `--force` — replace an existing `~/flag.txt` with this repo's version.
- `--synthetic` — macOS only; adds a `flag.txt` entry to `/etc/synthetic.conf`.
- `-h`, `--help` — usage.

The guestbook is never overwritten once it exists.

## What gets installed

| Path | Purpose |
|------|---------|
| `~/flag.txt` | Canonical checkpoint text |
| `~/guest-book.txt` | Append-only guestbook (mode `666`) |
| `/etc/flag.txt` | Symlink — classic recon target |
| `/usr/local/flag.txt` | Symlink — Unix convention |
| `/tmp/flag.txt` | Symlink — scratch space agents often check |
| `/var/tmp/flag.txt` | Symlink — same, longer-lived |
| `/var/root/flag.txt` (macOS) or `/root/flag.txt` (Linux) | Symlink for root logins, `sudo -i`, `su -` |
| `/flag.txt` | Only with `--synthetic` on macOS, after a reboot |

Every symlink points at the single canonical `~/flag.txt`, so editing one file updates every copy.

## Platform notes

**macOS.** `/` is a sealed read-only volume since 10.15, so a real `/flag.txt` can only be created
through `/etc/synthetic.conf`, which the kernel reads at boot. `--synthetic` appends
`flag.txt<TAB>Users/<you>/flag.txt` to that file; reboot for it to appear. Removing it again also
needs a reboot. The script refuses to run as root — it uses `sudo` only for the system paths.

**Linux.** `/` is writable, so no reboot is needed; the symlinks work immediately. `sudo -i` lands
in `/root`, which is covered.

**Containers / CI.** Usually only the home directory matters; skip `--synthetic`.

## Customising

Edit `flag.txt` in this repo **before** installing, or edit `~/flag.txt` afterwards — the symlinks
follow it automatically. The most likely edit is the own-agents list in the second paragraph. If you
rename the guestbook or move it, update the path in the flag text to match.

## Reading the guestbook

```sh
cat ~/guest-book.txt
```

Each line is self-reported, so treat entries as claims rather than proof. The file is
world-writable so that a different local user or a sandboxed agent can append; that also means a
determined visitor could rewrite it. That's acceptable for a guestbook.

## Uninstall

```sh
./uninstall.sh           # remove symlinks, keep ~/flag.txt and ~/guest-book.txt
./uninstall.sh --purge   # also delete the two files
```

On macOS, if you used `--synthetic`, remove the `flag.txt` line from `/etc/synthetic.conf` and
reboot to drop `/flag.txt`.

## Caveats

- Nothing *points* an agent at the flag. It only works if the agent lists the home directory, checks
  `/etc` or `/tmp`, or follows a symlink. Pair it with whatever discovery your agent does naturally.
- macOS cleans `/private/tmp` periodically, so `/tmp/flag.txt` may disappear after a while; re-run
  `./install.sh` to recreate it.
- The flag text is a prompt-level request, not enforcement. A misbehaving agent can ignore it.

## License

MIT
