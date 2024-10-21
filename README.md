# Ladybird Browser Ebuilds

This Repository contains Gentoo ebuilds for:

- simdutf

- Skia

- Ladybird


## Scope

If you want to contribute to Ladybird development,

This is for you


##### Disclaimer

Skia and Ladybird have been pached heavily to ensure skia libraries have a prefix


### Debugging

```
lddtree /usr/lib64/skia/libskia.so
libskia.so => /usr/lib64/skia/libskia.so (interpreter => none)
    libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1
    libfreetype.so.6 => /usr/lib64/libfreetype.so.6
        libz.so.1 => /usr/lib64/libz.so.1
        libbz2.so.1 => /usr/lib64/libbz2.so.1
    libexpat.so.1 => /usr/lib64/libexpat.so.1
    libGL.so.1 => /usr/lib64/libGL.so.1
        libGLdispatch.so.0 => /usr/lib64/libGLdispatch.so.0
        libGLX.so.0 => /usr/lib64/libGLX.so.0
            libX11.so.6 => /usr/lib64/libX11.so.6
                libxcb.so.1 => /usr/lib64/libxcb.so.1
                    libXau.so.6 => /usr/lib64/libXau.so.6
                    libXdmcp.so.6 => /usr/lib64/libXdmcp.so.6
    libjpeg.so.62 => /usr/lib64/libjpeg.so.62
    libpng16.so.16 => /usr/lib64/libpng16.so.16
    libwebp.so.7 => /usr/lib64/libwebp.so.7
        libsharpyuv.so.0 => /usr/lib64/libsharpyuv.so.0
    libwebpdemux.so.2 => /usr/lib64/libwebpdemux.so.2
    libwebpmux.so.3 => /usr/lib64/libwebpmux.so.3
    libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6
    libm.so.6 => /usr/lib64/libm.so.6
    libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1
    libc.so.6 => /usr/lib64/libc.so.6
    ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2
```

```
lddtree /usr/lib64/skia/libskparagraph.so
libskparagraph.so => /usr/lib64/skia/libskparagraph.so (interpreter => none)
    libskia.so => /usr/lib64/libskia.so
        ...
    libskshaper.so => /usr/lib64/skia/libskshaper.so
    libskunicode_core.so => /usr/lib64/skia/libskunicode_core.so
    libskunicode_icu.so => /usr/lib64/skia/libskunicode_icu.so
    libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1
    libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6
    libm.so.6 => /usr/lib64/libm.so.6
    libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1
    libc.so.6 => /usr/lib64/libc.so.6
```

```
lddtree /usr/lib64/skia/libskshaper.so
libskshaper.so => /usr/lib64/skia/libskshaper.so (interpreter => none)
    libskia.so => /usr/lib64/libskia.so
        ...
    libskunicode_core.so => /usr/lib64/skia/libskunicode_core.so
    libskunicode_icu.so => /usr/lib64/skia/libskunicode_icu.so
    libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1
    libharfbuzz.so.0 => /usr/lib64/libharfbuzz.so.0
        libglib-2.0.so.0 => /usr/lib64/libglib-2.0.so.0
            libpcre2-8.so.0 => /usr/lib64/libpcre2-8.so.0
    libharfbuzz-subset.so.0 => /usr/lib64/libharfbuzz-subset.so.0
    libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6
    libm.so.6 => /usr/lib64/libm.so.6
    libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1
    libc.so.6 => /usr/lib64/libc.so.6
```

```
lddtree /usr/lib64/skia/libskunicode_core.so
libskunicode_core.so => /usr/lib64/skia/libskunicode_core.so (interpreter => none)
    libskia.so => /usr/lib64/libskia.so
        ...
    libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1
    libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6
    libm.so.6 => /usr/lib64/libm.so.6
    libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1
    libc.so.6 => /usr/lib64/libc.so.6
```

```
lddtree /usr/lib64/skia/libskunicode_icu.so
libskunicode_icu.so => /usr/lib64/skia/libskunicode_icu.so (interpreter => none)
    libskunicode_core.so => /usr/lib64/skia/libskunicode_core.so
    libskia.so => /usr/lib64/libskia.so
        ...
    libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1
    libicuuc.so.74 => /usr/lib64/libicuuc.so.74
        libicudata.so.74 => /usr/lib64/libicudata.so.74
    libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6
    libm.so.6 => /usr/lib64/libm.so.6
    libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1
    libc.so.6 => /usr/lib64/libc.so.6
```
