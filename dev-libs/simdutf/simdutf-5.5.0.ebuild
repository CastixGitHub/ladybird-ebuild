# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3
inherit cmake

DESCRIPTION="Unicode and base64 @GB/s"
HOMEPAGE="https://simdutf.github.io/simdutf"
#SRC_URI="https://github.com/simdutf/simdutf/releases/download/v${PV}/singleheader.zip"
EGIT_REPO_URI="https://github.com/simdutf/simdutf"
EGIT_COMMIT="v${PV}" #"v5.5.0"

LICENSE="APACHE"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

src_configure() {
	#local cmakeargs=(
	#	$(cmake_use_find_package foo libFoo)
	#)
	cmake_src_configure
}
