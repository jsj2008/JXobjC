## Building ##

**JX Objective-C** is built with the [kBuild](http://trac.netlabs.org/kbuild/)
system, and has been built on Windows, FreeBSD, GNU/Linux, and more.

At present, JX Objective-C must be built in a Unix-like environment. MSYS2
is recommended for use on Windows. JXobjC is conceivably possible to compile
with Watcom, Microsoft Visual C++, and other compilers, but this is untested.
Support for Microsoft Visual C++ on Windows is an intermediate-term target, as
is a secondary build-system for those who find kBuild difficult to install.

If you experience an issue at any point in the process of building JX
Objective-C, please report it in a GitHub issue.

#### Unix-like (including MinGW on Windows) with cc-style compiler ####

Building JX Objective-C on Unix-like platforms is quite a simple process:

1. Install kBuild, which is linked above. It may be in your package repository
   if you run certain systems. Make sure it is in system path, such that you can
   run `kmk`.

2. Download and unpack a BootStrap! distribution from the Files section of the
   JXobjC GitHub page. Enter the directory in a terminal and run `sh build.sh`.

3. Files named `postlink` and `objc1` should have been deposited in the folder.
   These should be copied to a folder in the system path. `/usr/local/bin` is
   recommended.

4. Inspect the file `jxobjc`. Several variables, like C compiler path, are set
   in it. If these do not match your system, then adapt them. Now copy `jxobjc`
   into the same system-path folder as you copied `postlink` and `objc1`.

5. Collect a copy of the associated JX Objective-C source tree that corresponds
   to the BootStrap! distribution you downloaded. Unpack and run `kmk`. Now run
   `kmk install`.

6. Copy the resultant build tree into the path in which you have chosen to
   install JX Objective-C. For example, on FreeBSD with `/usr/local` as the
   JXobjC installation path, you would run `cp -r out/freebsd.amd64/debug/dist/*
   /usr/local/`.

7. If desired, repeat steps 5 and 6 in order to complete a 'three-stage'
   bootstrap.
