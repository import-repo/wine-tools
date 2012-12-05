/*
 * Copyright 2012 Francois Gouget
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */


/*
 * Compatiblity definitions.
 */

#ifdef WIN32
# include <ws2tcpip.h>
# include <windows.h>

# ifndef SHUT_RD
#  define SHUT_RD SD_RECEIVE
# endif

typedef unsigned int uint32_t;
typedef ULONGLONG uint64_t;
#define U64FMT "%I64u"

#else

# include <arpa/inet.h>
# include <sys/types.h>
# include <sys/socket.h>
# include <sys/select.h>
# include <netdb.h>

typedef int SOCKET;
# define closesocket(sock) close((sock))

#define U64FMT "%lu"
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif


/*
 * Platform-specific unctions.
 */

int platform_init(void);

enum run_flags_t {
    RUN_DNT = 1,
};

/* Starts the specified command in the background and reports the status to
 * the client.
 */
uint64_t platform_run(char** argv, uint32_t flags, char** redirects);

/* If a command was started in the background, waits until either that command
 * terminates or the client disconnects (typically because it got tired of
 * waiting).
 * If no command was started in the background, then reports an error
 * immediately.
 */
int platform_wait(SOCKET client, uint64_t pid, uint32_t *childstatus);

/* Returns a string describing the last socket-related error */
int sockeintr(void);
const char* sockerror(void);

/* Converts a socket address into a string stored in a static buffer. */
char* sockaddr_to_string(struct sockaddr* sa, socklen_t len);

int ta_getaddrinfo(const char *node, const char *service,
                   struct addrinfo **addresses);

void ta_freeaddrinfo(struct addrinfo *addresses);


/*
 * testagentd functions
 */

#ifdef __GNUC__
# define FORMAT(fmt, arg1)    __attribute__((format (printf, fmt, arg1) ))
#else
# define FORMAT(fmt, arg1)
#endif

void error(const char* format, ...) FORMAT(1,2);
void debug(const char* format, ...) FORMAT(1,2);

#define ST_OK       0
#define ST_ERROR    1
#define ST_FATAL    2
void set_status(int status, const char* format, ...) FORMAT(2,3);

void* sockaddr_getaddr(const struct sockaddr* sa, socklen_t* len);
