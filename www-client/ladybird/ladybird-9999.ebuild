# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
LLVM_COMPAT=( 18 19 )
LLVM_OPTIONAL="yeah"
inherit git-r3 cmake llvm-r1

DESCRIPTION="Truly independent web browser"
LICENSE="BSD-2"
HOMEPAGE="https://ladybird.org"
EGIT_REPO_URI="https://github.com/ladybirdbrowser/ladybird.git"
EGIT_BRANCH="master"
# Is pinning to a commit allowed with 9999? We don't have an upstream version number and
# following HEAD leads to broken builds. People using this ebuild should fall into two camps
# in any case: those that just want to try to run it (will benefit from a pinned commit)
# and those that will use EGIT_OVERRIDE_REPO_LADYBIRDBROWSER_LADYBIRD.
EGIT_COMMIT="8b1f1ae87ae3a459561d899dbf46e5a5595999ae"
#https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip
SRC_URI="
https://raw.githubusercontent.com/publicsuffix/list/76dbfcab5c3f0b1ac4e78ebeb6273a8b4db74ab7/public_suffix_list.dat -> suffixes
"
RESTRICT="mirror"

SLOT="0"
KEYWORDS=""

IUSE="clang"

# how to version check skia on 9999?
DEPEND="
	>=media-libs/skia-129
	media-libs/angle
	media-libs/libjxl
	media-libs/libwebp
	media-libs/libavif
	>=media-libs/libpng-1.6.45[apng]
	media-libs/woff2
	media-libs/libglvnd
	virtual/libcrypt
	dev-db/sqlite
	dev-libs/icu
	dev-cpp/fast_float
	>=dev-cpp/simdutf-7.3.0
	dev-qt/qtbase:6[network,widgets,gui]
	app-misc/ca-certificates
"
RDEPEND="${DEPEND}"
BDEPEND="
	clang? (
		$(llvm_gen_dep '
			llvm-core/clang:${LLVM_SLOT}=
			llvm-core/llvm:${LLVM_SLOT}=
		')
	)
	virtual/pkgconfig
"

pkg_setup() {
	llvm-r1_pkg_setup
}

src_prepare() {
    # This patch hardcodes lib64. Does that break multilib conventions?
    eapply "${FILESDIR}"/Libraries/LibGfx/CMakeLists.txt.patch
    eapply "${FILESDIR}"/Libraries/LibWeb/CMakeLists.txt.patch
    # Patch to make sure Angle's GLESv2 is used instead of the system one. Could also use patchelf
    eapply "${FILESDIR}"/Meta/CMake/lagom_install_options.cmake.patch
    eapply "${FILESDIR}"/Meta/CMake/skia.cmake.patch
	# temporary workaround my last skia install
	#sed -i ${S}/vcpkg.json -e s/129#0/130#0/ || die "unable to patch required skia version"

	# took from a nix issue/pull... idk why the '' thing (seems just broken to me)
	cat > ${S}/Meta/CMake/FindWebP.cmake<<EOF
find_package(PkgConfig)
pkg_check_modules(WEBP libwebp REQUIRED)
include_directories(''${WEBP_INCLUDE_DIRS})
link_directories(''${WEBP_LIBRARY_DIRS})
EOF
	# added some more love
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e "s/find_package(WebP REQUIRED)/pkg_check_modules(WebP REQUIRED IMPORTED_TARGET libwebp)\nfind_package(WebP REQUIRED IMPORTED TARGET)/" || die "unable to patch"
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e s/WebP::webp/webp/g || die "unable to patch"
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e s/WebP::libwebp/webp/g || die "unable to patch"
	# dear cmake understander: see build.ninja patched below. this makes no sense to me
	#sed -i ${S}/AK/CMakeLists.txt -e "s/find_package(simdutf REQUIRED)/find_package(PkgConfig)\npkg_check_modules(simdutf REQUIRED IMPORTED_TARGET GLOBAL)\nfind_package(simdutf REQUIRED SHARED)/g" || die "unable to patch"

    # This is now covered by a patch
	# patch WebGL linking with GLESv2
	# sed -i "${S}/Libraries/LibWeb/CMakeLists.txt" \
	# 	-e "s/\(target_link_libraries(LibWeb\)\([^)]*\)/\1\2 GLESv2 GL/" \
	# 	|| die "Unable to add GLESv2 linking"

	# patch skia include paths
	echo "patching skia includes..." 1>&2
	for f in $(find ${S}/Libraries -type f -regex '.*\.[h|c]p*p*$') ; do
        # commenting out a bit of spam :)
		# echo "patching $f" 1>&2
		# patching all "include <whatever/SkSomething>"
		# into "include <skia/whatever/SkSomething>"
		# but skipping <LibGfx/SkiaBackendContext.h>
		# through a negative lookbehind ?<!
		sed \
			-e 's@include <\([^/]*\)\(?<!LibGfx\)/Sk@include <skia/\1/Sk@g' \
			-e 's@include <gpu/\([^>]*\)@include <skia/gpu/\1@g' \
			-i ${f} || die "unable to patch skia includes $f"
	done

	# patch cmake copying a file it didn't download
	sed -i ${S}/Meta/CMake/ca_certificates_data.cmake \
		-e 's@^.*configure_file.*$@#&@'
	# patching cmake verify globs
	mkdir -p ${S}/Lagom || die "unable to create directory"

	ln -s /etc/ssl/certs/ca-certificates.crt ${S}/Lagom/cacert.pem || die "unable to copy ca-certificates"

	cmake_src_prepare
	eapply_user
}

src_configure() {
	local mycmakeargs=(
		-DENABLE_NETWORK_DOWNLOADS=OFF
	)
	mkdir -p ${BUILD_DIR}/caches/CACERT/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/caches/PublicSuffix/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/Lagom/ || dir "unable to mkdir"
	ln -s /etc/ssl/certs/ca-certificates.crt ${BUILD_DIR}/Lagom/cacert.pem || die "unable to copy ca-certificates"
	ln -s /etc/ssl/certs/ca-certificates.crt ${BUILD_DIR}/caches/CACERT/cacert-2023-12-12.pem || die "copying CA root"
	cp /var/cache/distfiles/suffixes ${BUILD_DIR}/caches/PublicSuffix/public_suffix_list.dat || dir "copying suffixes"
	cmake_src_configure

	# i don't get cmake. it's a total waste of time on the docs while patching the generated is easy
	# 1. webp is lib prefixed...
	# 2. it chooses the libsimdutf.a instead .so when everywhere the opposite is stated
	# 3. Ladybird also uses skcms to do color correction on images. This one is better not to come from pkg-config I think. If you wonder, Ladybird's skia is vendored: they do some visibility hack instead of statically linking skcms (we should do this the cmake way)
	sed -i ${BUILD_DIR}/build.ninja \
		-e 's@/usr/local/\(lib[0-9]*\)/libsimdutf.a@/usr/\1/libsimdutf.so@g' \
		-e 's/-llibwebpmux/-lwebpmux/g' \
		-e "s@skia.so@skia.so /usr/$(get_libdir)/skia/libskcms.a@g" \
		|| die "unable to patch build.ninja"
}

src_compile() {
	cd ${BUILD_DIR}/
	cmake_src_compile
}

postinst() {
    xdg_desktop_database_update
}

postrm() {
    xdg_desktop_database_update
}

