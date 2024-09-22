Additional resources:
 * [proof of concept in C](poc/x11-poc.c)
 * [access control](#access-control)
 * XCB implementations
    * [Apple][1]
    * [XOrg][2]

# Access Control
Experiments suggest running the following before any connection attempts:

```sh
xhost + local:
```

# Troubleshooting

## No protocol specified
This is probably because [access control](#access-control) wasn't properly
configured.

Further info: [No protocol specified][3]

# Links
 * [1]: <https://opensource.apple.com/source/X11libs/X11libs-17.3/libxcb/libxcb-1.0/src/xcb_util.c.auto.html> "Apple xcb_util.c"
 * [2]: <https://gitlab.freedesktop.org/xorg/lib/libxcb/-/blob/master/src/xcb_util.c> "XOrg xcb_util.c"
 * [3]: <https://unix.stackexchange.com/questions/209746/how-to-resolve-no-protocol-specified-for-su-user> "Stack Exchange - How to resolve ..."
