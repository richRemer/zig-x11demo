# Additional Resources
 * [access control](#access-control)
 * [troubleshooting](#troubleshooting)
 * [proof of concept in C](poc/x11-poc.c)
 * [XCB implementation - Apple][1]
 * [XCB implementation - XOrg][2]
 * [X11 Protocol][5]
 * [X.org Reply][6]

# Access Control
Experiments suggest running the following before any connection attempts:

```sh
xhost + local:
```

# Handshake
From [XOrg implementation of XCB][2] (irrelevant bits snipped):

```c
#define X_PROTOCOL 11
#define X_PROTOCOL_REVISION 0

typedef struct xcb_setup_request_t {
    uint8_t  byte_order;
    uint8_t  pad0;
    uint16_t protocol_major_version;
    uint16_t protocol_minor_version;
    uint16_t authorization_protocol_name_len;
    uint16_t authorization_protocol_data_len;
    uint8_t  pad1[2];
} xcb_setup_request_t;

static const uint32_t endian = 0x01020304;
static const char pad[3];
int count = 2; // len of parts

xcb_setup_request_t out;
memset(&out, 0, sizeof(out));
out.byte_order = htonl(endian) == endian ? 0x42 : 0x6c;
out.protocol_major_version = X_PROTOCOL;
out.protocol_minor_version = X_PROTOCOL_REVISION;
out.authorization_protocol_name_len = 0;
out.authorization_protocol_data_len = 0;

struct iovec parts[count];
parts[0].iov_len = sizeof(xcb_setup_request_t);
parts[0].iov_base = &out;
parts[1].iov_len = XCB_PAD(sizeof(xcb_setup_request_t)); // XCB_PAD to 4 bytes
parts[1].iov_base = (char *) pad;

// c is a connection
pthread_mutex_lock(&c->iolock);
_xcb_out_send(c, parts, count);
pthread_mutex_unlock(&c->iolock);
```

# Troubleshooting

## No protocol specified
This is probably because [access control](#access-control) wasn't properly
configured.

Further info: [No protocol specified][4]

# End Notes
[1]: <https://opensource.apple.com/source/X11libs/X11libs-17.3/libxcb/libxcb-1.0/src/xcb_util.c.auto.html> "Apple xcb_util.c"

[2]: <https://gitlab.freedesktop.org/xorg/lib/libxcb/-/blob/master/src/xcb_util.c> "XOrg xcb_util.c"

[3]: <https://www.x.org/releases/X11R7.6/doc/xproto/x11protocol.html> "X Window System Protocol"

[4]: <https://unix.stackexchange.com/questions/209746/how-to-resolve-no-protocol-specified-for-su-user> "Stack Exchange - How to resolve ..."

[5]: <https://stackoverflow.com/questions/9644251/how-do-unix-domain-sockets-differentiate-between-multiple-clients> "UNIX sockets with multiple clients"

[6]: <https://cgit.freedesktop.org/xorg/proto/xproto/tree/Xproto.h> "Xproto.h"
