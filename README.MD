D Language bindings and high level wrapper for the systemd journal logging service (journalctl)
written by Laeeth Isharc 2015.
alpha status

rather than grep /var/log/messages, systemd interface makes it easy to filter by field and period
of interest.  metadata is stored along with regular log messages, which reduces the ability of
bad actors to spoof logs.  tools for managing systemd logs have been somewhat limited, and I
hope you will find these bindings of help.

Link to C API here:
http://www.freedesktop.org/software/systemd/man/sd-journal.html

Description

systemd-journald is a system service that collects and stores logging data. It creates and maintains structured, indexed journals based on logging information that is received from a variety of sources:

    Kernel log messages, via kmsg

    Simple system log messages, via the libc syslog(3) call

    Structured system log messages via the native Journal API, see sd_journal_print(4)

    Standard output and standard error of system services

    Audit records, via the audit subsystem

The daemon will implicitly collect numerous metadata fields for each log messages in a secure and unfakeable way. See systemd.journal-fields(7) for more information about the collected metadata.

Log data collected by the journal is primarily text-based but can also include binary data where necessary. All objects stored in the journal can be up to 2^64-1 bytes in size.
