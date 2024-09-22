Additional resources:
 * [proof of concept in C](poc/x11-poc.c)
 * [access control](#access-control)
 * XCB implementations
    * [Apple](https://opensource.apple.com/source/X11libs/X11libs-17.3/libxcb/libxcb-1.0/src/xcb_util.c.auto.html)
    * [XOrg](https://gitlab.freedesktop.org/xorg/lib/libxcb/-/blob/master/src/xcb_util.c)

# Access Control
Experiments suggest running the following before any connection attempts:

```sh
xhost + local:
```

# Troubleshooting

## No protocol specified
This is probably because [access control](#access-control) wasn't properly
configured.
