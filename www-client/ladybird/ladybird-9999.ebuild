# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3 cmake

DESCRIPTION="Truly independent web browser"
HOMEPAGE="https://ladybird.org"
EGIT_REPO_URI="https://github.com/ladybirdbrowser/ladybird.git"
EGIT_COMMIT="HEAD"
#https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip
SRC_URI="
https://curl.se/ca/cacert-2023-12-12.pem -> cacert
https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat -> suffixes
"
RESTRICT="mirror"

#LICENSE="BSD 2-Clause"
LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"

# clang takes 10h to 24 hours on my pc
# gcc 30minuts to 1 hour (my cpufreq is broken)

IUSE="+system-webp"

# how to version check skia on 9999?
DEPEND="
	media-libs/skia:129
	media-libs/libwebp
	virtual/libcrypt
	dev-db/sqlite
	dev-libs/icu
	dev-qt/qtbase:6[network,widgets,gui]
"
RDEPEND="${DEPEND}"
BDEPEND="
	clang? ( sys-devel/clang:18 )
"

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
	sed -i ${S}/Userland/Libraries/LibGfx/CMakeLists.txt -e "s/find_package(WebP REQUIRED)/pkg_check_modules(WebP REQUIRED IMPORTED_TARGET webp)\nfind_package(WebP REQUIRED IMPORTED TARGET)/" || die "unable to patch"
	sed -i ${S}/Userland/Libraries/LibGfx/CMakeLists.txt -e s/WebP::webp/webp/g || die "unable to patch"
	sed -i ${S}/Userland/Libraries/LibGfx/CMakeLists.txt -e s/WebP::libwebp/webp/g || die "unable to patch"
	# dear cmake understander: see build.ninja patched below. this makes no sense to me
	#sed -i ${S}/AK/CMakeLists.txt -e "s/find_package(simdutf REQUIRED)/find_package(PkgConfig)\npkg_check_modules(simdutf REQUIRED IMPORTED_TARGET GLOBAL)\nfind_package(simdutf REQUIRED SHARED)/g" || die "unable to patch"

	# patch skia include paths
	echo "patching..." 1>&2
	for f in $(find ${S}/Userland/Libraries -type f -regex '.*\.[h|c]p*p*$') ; do
		echo "patching $f" 1>&2
		sed \
			-e 's@include <\([^/]*\)/Sk@include <skia/\1/Sk@g' \
			-e 's@include <gpu/\([^>]*\)@include <skia/gpu/\1@g' \
			-i ${f} || die "unable to patch skia includes $f"
	done

	# patch cmake copying a file it dodn't download
	sed -i ${S}/Meta/CMake/ca_certificates_data.cmake \
		-e 's@^.*configure_file.*$@#&@'
	# patching cmake verify globs
	mkdir -p ${S}/Lagom || die "unable to create directory"
	cp /var/cache/distfiles/cacert-2023-12-12.pem ${S}/Lagom/cacert.pem || die "unable to copy mozilla cert root"
	#cp /var/cache/distfiles/public_suffix_list.dat ${S}/downloads/ || die "unable to copy publix suffix list"

	# this setrlimit is invalid
	# prlimit64(0, RLIMIT_NOFILE, {rlim_cur=8*1024, rlim_max=4*1024}, NULL) = -1 EINVAL (Inval      id argument)
	# write(2, "Unable to increase open file limit: setrlimit: Invalid argument (errno=22)\n",       75) = 75
	# also it feels weird to have so many file descriptors simultaneously, even for 15 tabs.
	# don't they get closed? like mapped to memory, cached or something...
	sed -i ${S}/Userland/Libraries/LibWebView/ChromeProcess.cpp \
		-e 's/8192/4096/' || or die "unable to patch setrlimit"

	cmake_src_prepare
	eapply_user
}

src_configure() {
	local mycmakeargs=(
		# actually everything is system (nothing is patched) just slot them properly
		#$(cmake_use_find_package system-skia skia)
		$(cmake_use_find_package system-webp webp)
		-DENABLE_NETWORK_DOWNLOADS=OFF
		-DSERENITY_CACHE_DIR=${BUILD_DIR}/downloads
	)
	mkdir -p ${BUILD_DIR}/downloads/CACERT/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/downloads/PublicSuffix/ || die "unable to mkdir"
	mkdir -p ${BUILD_DIR}/Lagom/ || dir "unable to mkdir"
	cp ${S}/Lagom/cacert.pem ${BUILD_DIR}/Lagom/cacert.pem || die "unable to copy mozilla cert root"
	cp /var/cache/distfiles/cacert ${BUILD_DIR}/downloads/CACERT/cacert-2023-12-12.pem || die "copying CA root"
	cp /var/cache/distfiles/suffixes ${BUILD_DIR}/downloads/PublicSuffix/public_suffix_list.dat || dir "copying suffixes"
	cmake_src_configure

	# i don't get cmake. it's a total waste of time on the docs while patching the generated is easy
	# webp is lib prefixed...
	# it chooses the libsimdutf.a instead .so when everywhere the opposite is stated
	# doesn't add -lskia where needed
	sed -i ${BUILD_DIR}/build.ninja \
		-e 's@/usr/local/lib64/libsimdutf.a@/usr/lib64/libsimdutf.so@g' \
		-e 's/-llibwebpmux/-lwebpmux/g' \
		-e 's@^  LINK_LIBRARIES.*liblagom-gfx.so.*$@& -lskia@' \
		|| die "unable to patch build.ninja"
}

src_compile() {
	cd ${BUILD_DIR}/
	cmake_src_compile
}
