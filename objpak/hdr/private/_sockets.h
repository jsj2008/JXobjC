#ifndef __SOCKETS__H__
#define __SOCKETS__H__

#if defined(OBJC_WINDOWS)
#if defined(__MINGW32__)
#include <_mingw.h>
#if defined(__MINGW64_VERSION_MAJOR)
#include <winsock2.h>
#endif
#endif
#include <windows.h>
#include <ws2tcpip.h>
#define sockclose(socket) closesocket (socket)
#else
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#define sockclose(socket) close (socket)
#endif

#endif