# Changelog
We do not currently release this software using formal release cycles, the version numbers are best-effort only

## 1.2.0 (2023-07-17)
- Remove logging of zero process_id - resulting in misleading message in log.
- Fix logging of wrong process id for forth process in process tree.

## 1.1.0 (2023-06-19)
- Remove need for log config file
- Add check to ensure software is run as root, also ensure the log files are restricted to the running user.
- Add additional logging of HTTP request details (these include request method, url requested, IP and more)

## 1.0.0 (2023-04-01)
Initial release.

**Closed issues:**

**Merged pull requests:**
