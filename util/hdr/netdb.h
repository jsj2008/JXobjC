#pragma printLine #include <netdb.h>
#pragma printLine #define NETDB_INCLUDED

#pragma OCbuiltInType struct hostent

#pragma printLine #if 0

struct sockaddr {
    unsigned short  sa_family;
    char    sa_data[14];
};

struct sockaddr_in {
    short   sin_family;
    unsigned short sin_port;
    struct  in_addr sin_addr;
    char    sin_zero[8];
};

struct addrinfo {
    int             ai_flags;
    int             ai_family;
    int             ai_socktype;
    int             ai_protocol;
    int          ai_addrlen;
    char            *ai_canonname;
    struct sockaddr  *ai_addr;
    struct addrinfo  *ai_next;
};

#pragma printLine #endif