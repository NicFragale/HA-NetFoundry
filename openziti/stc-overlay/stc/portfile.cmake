vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO stclib/STC
    REF "v${VERSION}"
    SHA512 99ac97d4849e548c54d564e822cec36be6436b976546af1e8f12757764831c14229f958e7064ab8802e74131831a0016cc28649df24088c415ab4cdc65dad076
    HEAD_REF master
    PATCHES
        add-pkg-conf.patch
)

# GCC 14 + C11 mode makes implicit-function-declaration and implicit-int hard errors.
# Pass -Wno flags via c_args so the stc library compiles on Alpine/musl/GCC 14.
vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${BUILD_OPTIONS}
        -Dcheckscoped=disabled
        -Dtests=disabled
        -Dexamples=disabled
        -Dwerror=false
)
vcpkg_install_meson()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/doc")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
