# Changelog
We do not currently release this software using formal release cycles, the version numbers are best-effort only

## 1.5.0 (2025-10-17)
- Fix BPF compilation errors on AL2023 kernel 6.12+ by adding forward declarations for incomplete BPF structs
- Fix IMDSv2 calls not being written to log files by correcting logger level configuration

## 1.4.0 (2024-09-10)
- Change to redact tokens from the log messages as tokens were logged as a result of adding the headers.  Log file (and folder) has always been accessible only by root user.  

## 1.3.0 (2023-10-09)
- Remove the After dependency on the `multi-user.target` as it is not needed and causes a possible cyclic dependency.

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
