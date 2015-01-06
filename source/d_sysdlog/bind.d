module d_sysdlog.bind;
extern(C):
import std.c.stdlib;

/***
  This file is part of systemd.

  Copyright 2011 Lennart Poettering

  systemd is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2.1 of the License, or
  (at your option) any later version.

  systemd is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with systemd; If not, see <http://www.gnu.org/licenses/>.

  Ported to D 2015 by Laeeth Isharc
***/

alias uint64_t=ulong;
alias uint32_t=uint;
alias uint16_t=ushort;
alias uint8_t=ubyte;
alias int64_t=long;
alias int32_t=int;
alias int16_t=short;
alias int8_t=char;

alias sd_id128_t=sd_id128 ;

union sd_id128 {
        uint8_t bytes[16];
        uint64_t qwords[2];
}
struct iovec
  {
    void *iov_base;	/* Pointer to data.  */
    size_t iov_len;	/* Length of data.  */
  };

int sd_journal_sendv( iovec *iov, int n);
int sd_journal_perror(const(char*)message);
int sd_journal_sendv_with_location(const(char*)file, const(char*)line, const(char*)func, const  iovec *iov, int n);
int sd_journal_perror_with_location(const(char*)file, const(char*)line, const(char*)func, const(char*)message);
int sd_journal_stream_fd(const(char*)identifier, int priority, int level_prefix);

struct sd_journal;

/* Open flags */
enum {
        SD_JOURNAL_LOCAL_ONLY = 1,
        SD_JOURNAL_RUNTIME_ONLY = 2,
        SD_JOURNAL_SYSTEM = 4,
        SD_JOURNAL_CURRENT_USER = 8,
        SD_JOURNAL_SYSTEM_ONLY = SD_JOURNAL_SYSTEM, /* deprecated name */
};

enum OpenFlags
{
	LocalOnly=1,
	RunTimeOnly=2,
	System=4,
	CurrentUser=8,
	SystemOnly=4
}

/* Wakeup event types */
enum {
        SD_JOURNAL_NOP,
        SD_JOURNAL_APPEND,
        SD_JOURNAL_INVALIDATE
};

int sd_journal_open(sd_journal **ret, int flags);
int sd_journal_open_directory(sd_journal **ret, const(char*)path, int flags);
int sd_journal_open_files(sd_journal **ret, const(char*)*paths, int flags);
int sd_journal_open_container(sd_journal **ret, const(char*)machine, int flags);
void sd_journal_close(sd_journal *j);

int sd_journal_previous(sd_journal *j);
int sd_journal_next(sd_journal *j);

int sd_journal_previous_skip(sd_journal *j, uint64_t skip);
int sd_journal_next_skip(sd_journal *j, uint64_t skip);

int sd_journal_get_realtime_usec(sd_journal *j, uint64_t *ret);
int sd_journal_get_monotonic_usec(sd_journal *j, uint64_t *ret, sd_id128_t *ret_boot_id);

int sd_journal_set_data_threshold(sd_journal *j, size_t sz);
int sd_journal_get_data_threshold(sd_journal *j, size_t *sz);

int sd_journal_get_data(sd_journal *j, char*field, void **data, size_t *l);
int sd_journal_enumerate_data(sd_journal *j, const void **data, size_t *l);
void sd_journal_restart_data(sd_journal *j);

int sd_journal_add_match(sd_journal *j, const void *data, size_t size);
int sd_journal_add_disjunction(sd_journal *j);
int sd_journal_add_conjunction(sd_journal *j);
void sd_journal_flush_matches(sd_journal *j);

int sd_journal_seek_head(sd_journal *j);
int sd_journal_seek_tail(sd_journal *j);
int sd_journal_seek_monotonic_usec(sd_journal *j, sd_id128_t boot_id, uint64_t usec);
int sd_journal_seek_realtime_usec(sd_journal *j, uint64_t usec);
int sd_journal_seek_cursor(sd_journal *j, const(char*)cursor);

int sd_journal_get_cursor(sd_journal *j, char **cursor);
int sd_journal_test_cursor(sd_journal *j, const(char*)cursor);

int sd_journal_get_cutoff_realtime_usec(sd_journal *j, uint64_t *from, uint64_t *to);
int sd_journal_get_cutoff_monotonic_usec(sd_journal *j, const sd_id128_t boot_id, uint64_t *from, uint64_t *to);

int sd_journal_get_usage(sd_journal *j, uint64_t *bytes);

int sd_journal_query_unique(sd_journal *j, const(char*)field);
int sd_journal_enumerate_unique(sd_journal *j, const void **data, size_t *l);
void sd_journal_restart_unique(sd_journal *j);

int sd_journal_get_fd(sd_journal *j);
int sd_journal_get_events(sd_journal *j);
int sd_journal_get_timeout(sd_journal *j, uint64_t *timeout_usec);
int sd_journal_process(sd_journal *j);
int sd_journal_wait(sd_journal *j, uint64_t timeout_usec);
int sd_journal_reliable_fd(sd_journal *j);

int sd_journal_get_catalog(sd_journal *j, char **text);
int sd_journal_get_catalog_for_message_id(sd_id128_t id, char **text);
