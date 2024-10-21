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

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
#  VisibleVcsPkg: version 5.5.0: VCS version visible for KEYWORDS="~amd64", profile default/linux/amd64/23.0 (68 total)
#  What does this means?
#  Apparently we should not use any keyword for 9999 packages, but this is not, probably wants a tarball then.


src_configure() {
	#local cmakeargs=(
	#	$(cmake_use_find_package foo libFoo)
	#)
	cmake_src_configure
}
