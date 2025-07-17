# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
# NOTE: dawn seems to have angle as a submodule, causing a circular dependency. gclient resolves this but we don't use it to keep the network sandbox.
# NOTE: lunarg-vulkantools doesn't have HEAD and I don't know how to fetch that, but apparently we don't need it to get Ladybird running.

DESCRIPTION="ANGLE - Almost Native Graphics Layer Engine, translates OpenGL ES API calls to various hardware-supported graphics APIs like Vulkan, DirectX, and OpenGL."
HOMEPAGE="https://angleproject.org"

# TODO: get working with clang
# LLVM_COMPAT=( 18 19 )
# LLVM_OPTIONAL=1
inherit git-r3
# inherit git-r3 llvm-r1

EGIT_LFS=1
EGIT_REPO_URI="https://chromium.googlesource.com/angle/angle.git"
EGIT_BRANCH="main"
EGIT_COMMIT="ec2a04cc9535607a209989e093254d1290d0d2f5"

# Not using submodule for jsoncpp, see repo:angle/DEPS for the reason
SRC_URI="https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.6.tar.gz -> jsoncpp-1.9.6.tar.gz"

# TODO: which license?
# LICENSE="BSD-3-Clause"  # Vulkan Memory Allocator is MIT
LICENSE="BSD"  # Vulkan Memory Allocator is MIT
SLOT="${PV}"
KEYWORDS="~amd64"
CXX_FLAGS="-std=c++17"

# TODO: no clue if this is correct
# x11-libs/libX11
# x11-libs/libXext
# virtual/opengl
# dev-cpp/abseil-cpp
DEPEND=""
# dev-util/vulkan-headers
# vulkan? ( media-libs/vulkan-loader )
RDEPEND="${DEPEND}"
BDEPEND="
    dev-build/gn
"
# clang? (
#     $(llvm_gen_dep '
#     llvm-core/clang:${LLVM_SLOT}=
#     llvm-core/llvm:${LLVM_SLOT}=
#     ')
# )

# IUSE="clang vulkan"
IUSE="vulkan"
# Set submodules manually
EGIT_SUBMODULES=()

src_unpack() {
    EGIT_SUBMODULES=(
        # Core dependencies
        "build"
        "testing"
        "third_party/EGL-Registry/src"
        "third_party/OpenCL-CTS/src"
        "third_party/OpenCL-Docs/src"
        "third_party/OpenCL-ICD-Loader/src"
        "third_party/OpenGL-Registry/src"
        "third_party/Python-Markdown"
        "third_party/SwiftShader"
        "third_party/VK-GL-CTS/src"
        "third_party/abseil-cpp"
        "third_party/astc-encoder/src"
        "third_party/catapult"
        "third_party/cherry"
        "third_party/cpu_features/src"
        "third_party/flac"
        "third_party/flatbuffers/src"
        "third_party/glslang/src"
        "third_party/googletest"
        "third_party/gtest"
        "third_party/ijar"
        "third_party/jinja2"
        "third_party/jsoncpp"
        "third_party/libc++/src"
        "third_party/libc++abi/src"
        "third_party/libdrm/src"
        "third_party/libjpeg_turbo"
        "third_party/libpng/src"
        "third_party/libunwind/src"
        "third_party/llvm/src"
        "third_party/markupsafe"
        "third_party/nasm"
        "third_party/protobuf"
        "third_party/rapidjson/src"
        "third_party/re2/src"
        "third_party/rust"
        "third_party/spirv-cross/src"
        "third_party/spirv-headers/src"
        "third_party/spirv-tools/src"
        "third_party/vulkan-headers/src"
        "third_party/zlib"

        # Tools
        "tools/mb"
        "tools/protoc_wrapper"
        "tools/rust"
    )

    if use vulkan ; then
        EGIT_SUBMODULES+=(
            "third_party/vulkan_memory_allocator"
            "third_party/vulkan-loader/src"
            "third_party/vulkan-tools/src"
        )
    fi
    # if use clang ; then
    #     EGIT_SUBMODULES+=(
    #         "third_party/llvm/src"
    #     )
    # fi
    git-r3_fetch
    git-r3_checkout
}

src_prepare() {
    echo starting src_prepare
    echo CURDIR: $PWD

    eapply -p0 "${FILESDIR}"/7287-sysroot.gni.patch
    eapply -p0 "${FILESDIR}"/7287-test.gni.patch
    eapply -p0 "${FILESDIR}"/7287-config.BUILD.gn.patch
    eapply_user

    echo Removing gclient
    find -type f -name "*.gn*" | xargs sed -i 's/\(^import.*gclient_args.gni.*\)/# NO GCLIENT \1/'

    unpack jsoncpp-1.9.6.tar.gz
    rsync -a jsoncpp-1.9.6/ third_party/jsoncpp/source || die "moving jsoncpp failed"
}

src_configure() {
    # is_clang=$(usex clang 'true' 'false')
    local angle_args="
        angle_build_tests=false
        angle_enable_renderdoc=false
        angle_enable_swiftshader=false
        angle_enable_vulkan=$(usex vulkan 'true' 'false')
        angle_enable_wgpu=false
        angle_expose_non_conformant_extensions_and_versions=true
        angle_use_wayland=true
        angle_use_x11=false
        build_angle_deqp_tests=false
        chrome_pgo_phase=0
        is_cfi=false
        is_component_build=true
        is_debug=false
        is_official_build=true
        is_clang=false
        use_custom_libcxx=false
        use_safe_libstdcxx=true
        use_sysroot=false
        install_prefix=\"${D}/usr\"
    "

	# if use clang ; then
	# 	_LL_BIN="/usr/lib/llvm/${LLVM_SLOT}/bin/"
	# 	export CC="${_LL_BIN}clang"
	# 	export CXX="${_LL_BIN}clang++"
	# 	angle_args+="cc=\"${CC}\" cxx=\"${CXX}\" "
	# fi

    gn gen out --args="${angle_args}" || die "gn failed"
}
# src_compile() {
# }

src_install() {
    default
    ninja -C out install_angle zlib
    # Move to Gentoo's standard pkgconfig location
    dodir /usr/share/pkgconfig
    # Avoid collision with e.g. /usr/lib64/pkgconfig/glesv2.pc
    # I tried doing this with PKG_CONFIG_PATH but couldn't get it to work.
    # CMake would just default to /usr/lib64/pkgconfig/glesv2.pc
    for file in "${D}"/usr/lib/pkgconfig/*.pc
    do
        mv $file "${D}"/usr/share/pkgconfig/angle_$(basename $file)
    done

    rm -rf "${D}"/usr/lib/pkgconfig
    # Fix install_prefix  paths
    sed -i -E "s@/var/tmp/portage/media-libs/${PN}-[0-9]{4}/image@@g" "${D}"/usr/share/pkgconfig/*.pc
    sed -i -E "s@libdir=.*@libdir=\${prefix}/$(get_libdir)/${PN}@g" "${D}"/usr/share/pkgconfig/*.pc
    sed -i -E "s@includedir=.*@includedir=\${prefix}/include/${PN}@g" "${D}"/usr/share/pkgconfig/*.pc
    # fix multilib
    dodir /usr/$(get_libdir)/${PN}
    rsync --remove-source-files -aq "${D}"/usr/lib/ "${D}"/usr/$(get_libdir)/${PN}
    rm -rf "${D}"/usr/lib
    # avoid collisions with libglvnd and mesa
    mv "${D}"/usr/include "${D}"/${PN}
    dodir /usr/include/${PN}
    mv "${D}"/${PN} "${D}"/usr/include

    # Ladybird doesn't start without this. Skipped the related install sript.
    dolib.so "out/libchrome_zlib.so"
    # if use vulkan ; then
    #     dolib.so "out/libVkICD_mock_icd.so"
    #     dolib.so "out/libvulkan.so.1"
    # fi

    # make normal archives instead of thin ones
    ar rcs "${D}"/usr/$(get_libdir)/libangle_common.a ./out/obj/angle_common/*.o
    ar rcs "${D}"/usr/$(get_libdir)/libtranslator.a ./out/obj/translator/*.o
    ar rcs "${D}"/usr/$(get_libdir)/libangle_image_util.a ./out/obj/angle_image_util/*.o
    ar rcs "${D}"/usr/$(get_libdir)/libpreprocessor.a ./out/obj/preprocessor/*.o
    ar rcs "${D}"/usr/$(get_libdir)/libangle_gpu_info_util.a ./out/obj/angle_gpu_info_util/*.o
    ar rcs "${D}"/usr/$(get_libdir)/libangle_common_shader_state.a ./out/obj/angle_common_shader_state/*.o

	dodir /usr/share/pkgconfig
	cat > "${D}/usr/share/pkgconfig/angle.pc"<<EOF
prefix=/usr/$(get_libdir)
includedir=/usr/include/${PN}

Name: angle
Description: ${DESCRIPTION}
Version: ${PV}
Cflags: -I\${includedir}
Libs: -L\${prefix} -langle_common
EOF
}
