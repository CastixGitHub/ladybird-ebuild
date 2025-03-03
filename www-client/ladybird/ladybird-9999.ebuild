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
EGIT_COMMIT="HEAD"
#https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip
SRC_URI="
https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat -> suffixes
"
RESTRICT="mirror"

SLOT="0"
KEYWORDS=""

IUSE="clang"

# how to version check skia on 9999?
DEPEND="
	media-libs/skia:129
	media-libs/libwebp
	virtual/libcrypt
	dev-db/sqlite
	dev-libs/icu
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
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e "s/find_package(WebP REQUIRED)/pkg_check_modules(WebP REQUIRED IMPORTED_TARGET webp)\nfind_package(WebP REQUIRED IMPORTED TARGET)/" || die "unable to patch"
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e s/WebP::webp/webp/g || die "unable to patch"
	sed -i ${S}/Libraries/LibGfx/CMakeLists.txt -e s/WebP::libwebp/webp/g || die "unable to patch"
	# dear cmake understander: see build.ninja patched below. this makes no sense to me
	#sed -i ${S}/AK/CMakeLists.txt -e "s/find_package(simdutf REQUIRED)/find_package(PkgConfig)\npkg_check_modules(simdutf REQUIRED IMPORTED_TARGET GLOBAL)\nfind_package(simdutf REQUIRED SHARED)/g" || die "unable to patch"

	# patch skia include paths
	echo "patching..." 1>&2
	for f in $(find ${S}/Libraries -type f -regex '.*\.[h|c]p*p*$') ; do
		echo "patching $f" 1>&2
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
		-DSERENITY_CACHE_DIR=${BUILD_DIR}/downloads
	)
	mkdir -p ${BUILD_DIR}/downloads/CACERT/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/downloads/PublicSuffix/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/Lagom/ || dir "unable to mkdir"
	ln -s /etc/ssl/certs/ca-certificates.crt ${BUILD_DIR}/Lagom/cacert.pem || die "unable to copy ca-certificates"
	ln -s /etc/ssl/certs/ca-certificates.crt ${BUILD_DIR}/downloads/CACERT/cacert-2023-12-12.pem || die "copying CA root"
	cp /var/cache/distfiles/suffixes ${BUILD_DIR}/downloads/PublicSuffix/public_suffix_list.dat || dir "copying suffixes"
	cmake_src_configure

	# i don't get cmake. it's a total waste of time on the docs while patching the generated is easy
	# webp is lib prefixed...
	# it chooses the libsimdutf.a instead .so when everywhere the opposite is stated
	sed -i ${BUILD_DIR}/build.ninja \
		-e 's@/usr/local/\(lib[0-9]*\)/libsimdutf.a@/usr/\1/libsimdutf.so@g' \
		-e 's/-llibwebpmux/-lwebpmux/g' \
		|| die "unable to patch build.ninja"
}

src_compile() {
	cd ${BUILD_DIR}/
	cmake_src_compile
}
