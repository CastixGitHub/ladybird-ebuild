# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="Graphics engine for Chrome, Firefox, Ladybird, Android, Flutter"
HOMEPAGE="https://skia.org"
EGIT_REPO_URI="https://skia.googlesource.com/skia.git"
EGIT_BRANCH="chrome/m${PV}"

LICENSE="BSD"
SLOT="${PV}"
KEYWORDS="~amd64"

CXX_FLAGS="-std=c++17"  # should i prefer this or as arg to gn?

DEPEND="
	media-libs/webp
	media-libs/png
	media-libs/fontconfig
	media-libs/freetype
	media-libs/harfbuzz
	dev-libs/icu
	dev-libs/expat
"
RDEPEND="${DEPEND}"
# dev-util/spirv-tools for intel iGPUs
# spirv_validation is disabled, also, what is this thing?
BDEPEND="
	dev-build/gn
	dev-util/spirv-tools
"


# skia_use_system_ffmpeg=true \
# skia_use_system_fontconfig=true \
src_prepare() {
	gn gen out --args=" \
is_official_build=false \
is_component_build=true \
skia_use_system_expat=true \
skia_use_system_freetype2=true \
skia_use_system_harfbuzz=true \
skia_use_system_icu=true \
skia_use_system_libjpeg_turbo=true \
skia_use_system_libpng=true \
skia_use_system_libwebp=true \
skia_use_system_zlib=true \
skia_enable_spirv_validation=false \
skia_use_dng_sdk=false \
skia_use_wuffs=false \
skia_use_zlib=false \
"
	eapply_user
}

src_compile() {
	ninja -C out
}

src_install() {
	# installing header files
	dodir /usr/include/skia
	dodir /usr/include/skia/modules
	cp -a ${S}/include/* ${D}/usr/include/skia || die "Installing headers failed"
	# installing header files for modules
	for f in $(find ${S}/modules/ -type f -regex '.*\.h$') ; do
		if [[ $(basename $(dirname $f)) == "include" ]]; then
			dp=$D/usr/include/skia/modules/$(basename $(dirname $(dirname $f)))/$(basename $f)
		else
			dp=$D/usr/include/skia/modules/$(basename $(dirname $f))/$(basename $f)
		fi
		if [[ ! -d $(dirname $dp) ]] then
			echo "creating folder $(dirname $dp)" 2>&1
			mkdir -p $(dirname $dp) || die "unable to create a folder $(dirname $dp)"
		fi
		cp -a $f $dp || die "installing module headers $f -> $dp"
		sed \
		    -e 's@include "modules\([^"]*\)"@include <skia/modules\1>@g' \
			-i $dp \
			|| die "unable to patch $dp"
	done
	# specifically override skcms header
	cp -a $S/modules/skcms/src/skcms_public.h $D/usr/include/skia/modules/skcms/skcms.h
	# patching header files inclusion
	for f in $(find ${D}/usr/include/skia/ -type f -regex '.*\.h$') ; do
		echo "patching $f" 2>&1
		sed \
			-e 's@include "include\([^"]*\)"@include <skia\1>@g' \
		    -e 's@include "modules\([^"]*\)"@include <skia/modules\1>@g' \
			-i $f \
			|| die "unable to patch $f"
	done
	# libskcms.a libskshaper.so libbentleyottmann.so libskia.so libskunicode_core.so
	# libpathkit.a libskparagraph.so libskunicode_icu.so
	#
	# how to enable other archs?
	dodir /usr/lib64
	cp ${S}/out/*.so ${S}/out/*.a "${D}/usr/lib64" || die "Install failed!"
	# TODO: is this even needed?
	dodir /usr/share/pkgconfig
	cat > ${D}/usr/share/pkgconfig/skia.pc<<EOF
prefix=/usr/lib64
includedir=/usr/include/skia

Name: skia
Description: ${DESCRIPTION}
Version: ${PV}
Cflags: -I/usr/include
EOF
	einstalldocs
}

# skia_use_system_expat
#    Current value (from the default)=false
#      From //third_party/expat/BUILD.gn:7
#skia_use_system_freetype2
#    Current value (from the default)=true
#      From //third_party/freetype2/BUILD.gn:11
#skia_use_system_harfbuzz
#    Current value=true
#      From //out/args.gn:5
#    Overridden from the default=false
#      From //third_party/harfbuzz/BUILD.gn:10
#skia_use_system_icu
#    Current value=true
#      From //out/args.gn:7
#    Overridden from the default=false
#      From //third_party/icu/icu.gni:7
#
#skia_use_system_libjpeg_turbo
#    Current value (from the default)=false
#      From //third_party/libjpeg-turbo/BUILD.gn:7
#
#skia_use_system_libpng
#    Current value (from the default)=false
#      From //third_party/libpng/BUILD.gn:7
#
#skia_use_system_libwebp
#    Current value (from the default)=false
#      From //third_party/libwebp/BUILD.gn:7
#
#skia_use_system_zlib
#    Current value (from the default)=false
#      From //third_party/zlib/zlib.gni:7
#
#
# $ ldd /usr/lib64/libskia.so
#	linux-vdso.so.1 (0x00007ffceffd2000)
#	libfontconfig.so.1 => /usr/lib64/libfontconfig.so.1 (0x00007f7b0c11d000)
#	libfreetype.so.6 => /usr/lib64/libfreetype.so.6 (0x00007f7b0c001000)
#	libexpat.so.1 => /usr/lib64/libexpat.so.1 (0x00007f7b0bfd8000)
#	libGL.so.1 => /usr/lib64/libGL.so.1 (0x00007f7b0bf65000)
#	libjpeg.so.62 => /usr/lib64/libjpeg.so.62 (0x00007f7b0be4e000)
#	libpng16.so.16 => /usr/lib64/libpng16.so.16 (0x00007f7b0be01000)
#	libwebp.so.7 => /usr/lib64/libwebp.so.7 (0x00007f7b0bd4a000)
#	libwebpdemux.so.2 => /usr/lib64/libwebpdemux.so.2 (0x00007f7b0bd42000)
#	libwebpmux.so.3 => /usr/lib64/libwebpmux.so.3 (0x00007f7b0bd32000)
#	libstdc++.so.6 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libstdc++.so.6 (0x00007f7b0bacb000)
#	libm.so.6 => /usr/lib64/libm.so.6 (0x00007f7b0b9e1000)
#	libgcc_s.so.1 => /usr/lib/gcc/x86_64-pc-linux-gnu/13/libgcc_s.so.1 (0x00007f7b0b9bc000)
#	libc.so.6 => /usr/lib64/libc.so.6 (0x00007f7b0b7b9000)
#	/lib64/ld-linux-x86-64.so.2 (0x00007f7b0d45a000)
#	libz.so.1 => /usr/lib64/libz.so.1 (0x00007f7b0b794000)
#	libbz2.so.1 => /usr/lib64/libbz2.so.1 (0x00007f7b0b778000)
#	libGLdispatch.so.0 => /usr/lib64/libGLdispatch.so.0 (0x00007f7b0b6fd000)
#	libGLX.so.0 => /usr/lib64/libGLX.so.0 (0x00007f7b0b6c0000)
#	libsharpyuv.so.0 => /usr/lib64/libsharpyuv.so.0 (0x00007f7b0b6b4000)
#	libX11.so.6 => /usr/lib64/libX11.so.6 (0x00007f7b0b53c000)
#	libxcb.so.1 => /usr/lib64/libxcb.so.1 (0x00007f7b0b504000)
#	libXau.so.6 => /usr/lib64/libXau.so.6 (0x00007f7b0b4fe000)
#	libXdmcp.so.6 => /usr/lib64/libXdmcp.so.6 (0x00007f7b0b4f5000)

