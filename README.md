MinGW CRT DLL for use with MSVC
-----------------------------------------------------

#### Description: ####

This DLL allows you to statically link MinGW compiled libraries with MSVC.

#### Usage: ####

All you need to do, is to link against `mingw-crt-<arch>.lib`, that's it!

#### Generating your own MinGW-w64 CRT DLL: ####

To generate your own DLL from your own MinGW-w64 installation,  
simply run `./gen-<arch>-mingw-crt-dll.sh` in MSYS or on a Unix  
box with MinGW-w64 installed, Cygwin may also work.

#### Troubleshooting: ####

If you still get unresolved symbol errors, then you may need to adjust  
the symbol list in the script, then simply generate a new DLL and try again.
