# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
LLVM_COMPAT=( 17 18 )
LLVM_OPTIONAL="yeah"
inherit git-r3 llvm-r1

DESCRIPTION="Graphics engine for Chrome, Firefox, Ladybird, Android, Flutter"
HOMEPAGE="https://skia.org"
EGIT_REPO_URI="https://skia.googlesource.com/skia.git"
EGIT_BRANCH="chrome/m${PV}"

LICENSE="BSD"
SLOT="${PV}"
KEYWORDS="~amd64"
CXX_FLAGS="-std=c++17"


DEPEND="
	media-libs/libwebp
	media-libs/libpng
	media-libs/libjpeg-turbo
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
	clang? (
		$(llvm_gen_dep '
			sys-devel/clang:${LLVM_SLOT}=
			sys-devel/llvm:${LLVM_SLOT}=
		')
	)
	dev-util/spirv-tools
	dev-util/patchelf
"

IUSE="clang"

src_prepare() {
	local myskiaargs=""
	myskiaargs+=" \
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

	if use clang ; then
		_LL_BIN="/usr/lib/llvm/${LLVM_SLOT}/bin/"
		export CC="${_LL_BIN}clang"
		export CPP="${_LL_BIN}clang-cpp" # unecessary?
		export CXX="${_LL_BIN}clang++"
		myskiaargs+="cc=\"${CC}\" cxx=\"${CXX}\""
	fi

	gn gen out --args="${myskiaargs}"
	eapply_user
}

src_compile() {
	ninja -C out
}

src_install() {
	# installing header files
	dodir /usr/include/skia
	dodir /usr/include/skia/modules
	cp -a ${S}/include/* "${D}/usr/include/skia" || die "Installing headers failed"
	# installing header files for modules
	for f in $(find "${S}/modules/" -type f -regex '.*\.h$') ; do
		if [[ $(basename $(dirname $f)) == "include" ]]; then
			dp="$D/usr/include/skia/modules/$(basename $(dirname $(dirname $f)))/$(basename $f)"
		else
			dp="$D/usr/include/skia/modules/$(basename $(dirname $f))/$(basename $f)"
		fi
		if [[ ! -d $(dirname $dp) ]] then
			echo "creating folder $(dirname $dp)" 2>&1
			mkdir -p $(dirname $dp) || die "unable to create a folder $(dirname $dp)"
		fi
		# 01:18 < asdrubic1ble> sam_: i want a prefix, so as a workaround i suppose i can mkdir and mv every header into that
		# 01:18 <@sam_> ideally just fix the build system instead..
		cp -a $f $dp || die "installing module headers $f -> $dp"
		sed \
		    -e 's@include "modules\([^"]*\)"@include <skia/modules\1>@g' \
			-i $dp \
			|| die "unable to patch $dp"
	done
	# specifically override skcms header
	cp -a "$S/modules/skcms/src/skcms_public.h" \
		"$D/usr/include/skia/modules/skcms/skcms.h" \
		|| die "unable to copy skcms header"
	# patching header files inclusion
	for f in $(find ${D}/usr/include/skia/ -type f -regex '.*\.h$') ; do
		echo "patching $f" 2>&1
		sed \
			-e 's@include "include\([^"]*\)"@include <skia\1>@g' \
		    -e 's@include "modules\([^"]*\)"@include <skia/modules\1>@g' \
			-i $f \
			|| die "unable to patch $f"
	done
	ABILIBDIR="/usr/$(get_libdir)/skia"
	DLIBDIR="${D}${ABILIBDIR}"
	dodir "/usr/$(get_libdir)/skia"
	mkdir -p $DLIBDIR || die "unable to make a dir"

	# skia "modules"
	cp -a "${S}/out/libpathkit.a" \
		"${S}/out/libskcms.a" \
		"${S}/out/libbentleyottmann.so" \
		"$DLIBDIR" \
		|| die "unable to install skia modules"

	# actual skia
	cp -a "${S}/out/libskia.so" \
		"${S}/out/libskparagraph.so" \
		"${S}/out/libskshaper.so" \
		"${S}/out/libskunicode_core.so" \
		"${S}/out/libskunicode_icu.so" \
		"$DLIBDIR" \
		|| die "unable to install skia"

	chmod 644 $DLIBDIR/*.a
	chmod 755 $DLIBDIR/*.so

	# then replace paths
	patchelf --add-rpath "$ABILIBDIR"  \
		"$DLIBDIR/libskparagraph.so"
	patchelf --add-rpath "$ABILIBDIR"  \
		"$DLIBDIR/libskshaper.so"
	patchelf --add-rpath "$ABILIBDIR"  \
		"$DLIBDIR/libskunicode_core.so"
	patchelf --add-rpath "$ABILIBDIR"  \
		"$DLIBDIR/libskunicode_icu.so"
	#patchelf --replace-needed				\
	#	libskshaper.so						\
	#	"$ABILIBDIR/libskshaper.so"			\
	#	"$DLIBDIR/libskparagraph.so"		\
	#	|| die "unable to patchelf"
	#patchelf --replace-needed				\
	#	libskunicode_core.soc				\
	#	"$ABILIBDIR/libskunicode_core.so"	\
	#	"$DLIBDIR/libskparagraph.so"		\
	#	|| die "unable to patchelf"
	#patchelf --replace-needed				\
	#	libskunicode_icu.so					\
	#	"$ABILIBDIR/libskunicode_icu.so"	\
	#	"$DLIBDIR/libskparagraph.so"		\
	#	|| die "unable to patchelf"

	#patchelf --replace-needed				\
	#	libskunicode_core.so				\
	#	"$ABILIBDIR/libskunicode_core.so"	\
	#	"$DLIBDIR/libskshaper.so"			\
	#	|| die "unable to patchelf"
	#patchelf --replace-needed				\
	#	libskunicode_icu.so					\
	#	"$ABILIBDIR/libskunicode_icu.so"	\
	#	"$DLIBDIR/libskshaper.so"			\
	#	|| die "unable to patchelf"

	#patchelf --replace-needed				\
	#	libskunicode_core.so				\
	#	"$ABILIBDIR/libskunicode_core.so"	\
	#	"$DLIBDIR/libskunicode_icu.so"		\
	#	|| die "unable to patchelf"

	dodir /usr/share/pkgconfig
	cat > "${D}/usr/share/pkgconfig/skia.pc"<<EOF
prefix=${ABILIBDIR}
includedir=/usr/include/skia

Name: skia
Description: ${DESCRIPTION}
Version: ${PV}
Cflags: -I/usr/include/skia
Libs: -L${ABILIBDIR} -lskia
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
