#!/bin/bash

set -e

function ChToScriptFileDir() {
    cd "$(dirname "$0")"
}

function Init() {
    cd ..
    DIST="dist"
    mkdir -p "$DIST"
    OIFS="$IFS"
    IFS=$'\n\t, '

    if [ "$(uname)" == "Darwin" ]; then
        MAKE="gmake"
        TMP_BIN_DIR="$(mktemp -d)"
        PATH="$TMP_BIN_DIR:$PATH"
        trap "rm -rf \"$TMP_BIN_DIR\"" EXIT

        if [ -x "$(command -v gsed)" ]; then
            SED_PATH="$(command -v gsed)"
            ln -s "$SED_PATH" "$TMP_BIN_DIR/sed"
        else
            echo "Warn: gsed not found"
            echo "Warn: when sed is not gnu version, it may cause build error"
            echo "Warn: you can install gsed with brew"
            echo "Warn: brew install gnu-sed"
            sleep 3
        fi

        if [ -x "$(command -v glibtool)" ]; then
            LIBTOOL_PATH="$(command -v glibtool)"
            ln -s "$LIBTOOL_PATH" "$TMP_BIN_DIR/libtool"
        else
            echo "Warn: glibtool not found"
            echo "Warn: when libtool is not gnu version, it may cause build error"
            echo "Warn: you can install libtool with brew"
            echo "Warn: brew install libtool"
            sleep 3
        fi

        if [ -x "$(command -v greadlink)" ]; then
            READLINK_PATH="$(command -v greadlink)"
            ln -s "$READLINK_PATH" "$TMP_BIN_DIR/readlink"
        else
            echo "Warn: greadlink not found"
            echo "Warn: when readlink is not gnu version, it may cause build error"
            echo "Warn: you can install coreutils with brew"
            echo "Warn: brew install coreutils"
            sleep 3
        fi

        if [ -x "$(command -v gfind)" ]; then
            FIND_PATH="$(command -v gfind)"
            ln -s "$FIND_PATH" "$TMP_BIN_DIR/find"
        else
            echo "Warn: gfind not found"
            echo "Warn: when find is not gnu version, it may cause build error"
            echo "Warn: you can install findutils with brew"
            echo "Warn: brew install findutils"
            sleep 3
        fi

        if [ -x "$(command -v gawk)" ]; then
            AWK_PATH="$(command -v gawk)"
            ln -s "$AWK_PATH" "$TMP_BIN_DIR/awk"
        else
            echo "Warn: gawk not found"
            echo "Warn: when awk is not gnu version, it may cause build error"
            echo "Warn: you can install gawk with brew"
            echo "Warn: brew install gawk"
            sleep 3
        fi

        if [ -x "$(command -v gdate)" ]; then
            DATE_PATH="$(command -v gdate)"
            ln -s "$DATE_PATH" "$TMP_BIN_DIR/date"
        else
            echo "Warn: gdate not found"
            echo "Warn: when date is not gnu version, it may cause build error"
            echo "Warn: you can install coreutils with brew"
            echo "Warn: brew install coreutils"
            sleep 3
        fi

    else
        MAKE="make"
    fi

    {
        DEFAULT_CONFIG_SUB_REV="28ea239c53a2"
        DEFAULT_GCC_VER="13.2.0"
        DEFAULT_MUSL_VER="1.2.4"
        DEFAULT_BINUTILS_VER="2.41"
        DEFAULT_GMP_VER="6.3.0"
        DEFAULT_MPC_VER="1.3.1"
        DEFAULT_MPFR_VER="4.2.1"
        DEFAULT_ISL_VER="0.26"
        DEFAULT_LINUX_VER="4.19.274"
        DEFAULT_MINGW_VER="v11.0.1"
        if [ ! "$CONFIG_SUB_REV" ]; then
            CONFIG_SUB_REV="$DEFAULT_CONFIG_SUB_REV"
        fi
        if [ ! "$GCC_VER" ]; then
            GCC_VER="$DEFAULT_GCC_VER"
        fi
        if [ -z "${MUSL_VER+x}" ]; then
            MUSL_VER="$DEFAULT_MUSL_VER"
        fi
        if [ ! "$BINUTILS_VER" ]; then
            BINUTILS_VER="$DEFAULT_BINUTILS_VER"
        fi
        if [ ! "$GMP_VER" ]; then
            GMP_VER="$DEFAULT_GMP_VER"
        fi
        if [ ! "$MPC_VER" ]; then
            MPC_VER="$DEFAULT_MPC_VER"
        fi
        if [ ! "$MPFR_VER" ]; then
            MPFR_VER="$DEFAULT_MPFR_VER"
        fi
        if [ -z "${ISL_VER+x}" ]; then
            ISL_VER="$DEFAULT_ISL_VER"
        fi
        if [ -z "${LINUX_VER+x}" ]; then
            LINUX_VER="$DEFAULT_LINUX_VER"
        fi
        if [ -z "${MINGW_VER+x}" ]; then
            MINGW_VER="$DEFAULT_MINGW_VER"
        fi
    }
}

function Help() {
    echo "-h: help"
    echo "-a: enable archive"
    echo "-t: test build only"
    echo "-T: targets file path or targets string"
    echo "-C: use china mirror"
    echo "-c: set CC"
    echo "-x: set CXX"
    echo "-n: with native build"
    echo "-N: only native build"
    echo "-L: log to std"
    echo "-l: disable log to file"
    echo "-O: set optimize level"
    echo "-j: set job number"
    echo "-s: disable cross static build"
    echo "-S: disable native static build"
    echo "-p: dist name prefix"
    echo "-i: simpler build"
}

function ParseArgs() {
    while getopts "hatT:Cc:x:nLlO:j:sSNp:i" arg; do
        case $arg in
        h)
            Help
            exit 0
            ;;
        a)
            ENABLE_ARCHIVE="true"
            ;;
        t)
            TEST_BUILD_ONLY="true"
            ;;
        T)
            TARGETS_FILE="$OPTARG"
            ;;
        C)
            USE_CHINA_MIRROR="true"
            ;;
        c)
            CC="$OPTARG"
            ;;
        x)
            CXX="$OPTARG"
            ;;
        n)
            NATIVE_BUILD="true"
            ;;
        N)
            NATIVE_BUILD="true"
            ONLY_NATIVE_BUILD="true"
            ;;
        L)
            LOG_TO_STD="true"
            ;;
        l)
            DISABLE_LOG_TO_FILE="true"
            ;;
        O)
            OPTIMIZE_LEVEL="$OPTARG"
            ;;
        j)
            if [ "$OPTARG" -eq "$OPTARG" ] 2>/dev/null; then
                CPU_NUM="$OPTARG"
            else
                echo "cpu number must be number"
                exit 1
            fi
            ;;
        s)
            DISABLE_CROSS_STATIC_BUILD="true"
            ;;
        S)
            DISABLE_NATIVE_STATIC_BUILD="true"
            ;;
        p)
            DIST_NAME_PREFIX="$OPTARG"
            ;;
        i)
            SIMPLER_BUILD="true"
            ;;
        ?)
            echo "unkonw argument"
            exit 1
            ;;
        esac
    done
}

function FixArgs() {
    mkdir -p "${DIST}"
    DIST="$(cd "$DIST" && pwd)"
}

function Date() {
    date '+%H:%M:%S'
}

function WriteConfig() {
    cat >config.mak <<EOF
CONFIG_SUB_REV = ${CONFIG_SUB_REV}
TARGET = ${TARGET}
NATIVE = ${NATIVE}
OUTPUT = ${OUTPUT}
GCC_VER = ${GCC_VER}
MUSL_VER = ${MUSL_VER}
BINUTILS_VER = ${BINUTILS_VER}

ifneq (\$(findstring or1k,\$(TARGET)),)
# or1k
# in binutils 2.41, ld exit with code 11
BINUTILS_VER = 2.37
else
# \`--disable-gprofng\` fix gprofng: unknown type name off64_t in \`binutils version 2.38+\`
BINUTILS_CONFIG += --disable-gprofng
endif

GMP_VER = ${GMP_VER}
MPC_VER = ${MPC_VER}
MPFR_VER = ${MPFR_VER}
ISL_VER = ${ISL_VER}

LINUX_VER = ${LINUX_VER}
MINGW_VER = ${MINGW_VER}

# only work in cross build
# native build will find ${TARGET}-gcc ${TARGET}-g++ in env to build
ifneq (${CC}${CXX},)
CC = ${CC}
CXX = ${CXX}
endif

CHINA = ${USE_CHINA_MIRROR}
CPUS = ${CPU_NUM}
OPTIMIZE_LEVEL = ${OPTIMIZE_LEVEL}
DISABLE_CROSS_STATIC_BUILD = ${DISABLE_CROSS_STATIC_BUILD}
DISABLE_NATIVE_STATIC_BUILD = ${DISABLE_NATIVE_STATIC_BUILD}

SIMPLER_BUILD = ${SIMPLER_BUILD}

ifeq (\$(shell uname),Darwin)
# fix isl 0.25+ isl_test_cpp17 error
CXX += -std=gnu++17
endif

ifneq (\$(findstring 86-w64-mingw32,\$(TARGET)),)
# i486-w64-mingw32 i686-w64-mingw32
# disable tls in gcc 13.2.0
GCC_CONFIG += --disable-tls
endif

COMMON_CONFIG += --with-debug-prefix-map=\$(CURDIR)= --enable-compressed-debug-sections=none
EOF
}

function Build() {
    TARGET="$1"
    DIST_NAME="${DIST}/${DIST_NAME_PREFIX}${TARGET}"
    CROSS_DIST_NAME="${DIST_NAME}-cross"
    NATIVE_DIST_NAME="${DIST_NAME}-native"
    CROSS_LOG_FILE="${CROSS_DIST_NAME}.log"
    NATIVE_LOG_FILE="${NATIVE_DIST_NAME}.log"

    if [ ! "$ONLY_NATIVE_BUILD" ]; then
        echo "build cross ${DIST_NAME_PREFIX}${TARGET} to ${CROSS_DIST_NAME}"
        rm -rf "${CROSS_DIST_NAME}" "${CROSS_LOG_FILE}"
        $MAKE clean
        {
            OUTPUT="${CROSS_DIST_NAME}"
            NATIVE=""
        }
        WriteConfig
        while IFS= read -r line; do
            CURRENT_DATE=$(Date)
            if [ "$LOG_TO_STD" ]; then
                echo "[$CURRENT_DATE] ${DIST_NAME_PREFIX}${TARGET}-cross: $line"
            fi
            if [ ! "$DISABLE_LOG_TO_FILE" ]; then
                echo "[$CURRENT_DATE] $line" >>"${CROSS_LOG_FILE}"
            fi
        done < <(
            set +e
            $MAKE install 2>&1
            echo $? >"${CROSS_DIST_NAME}.exit"
        )
        read EXIT_CODE <"${CROSS_DIST_NAME}.exit"
        rm "${CROSS_DIST_NAME}.exit"
        if [ $EXIT_CODE -ne 0 ]; then
            if [ ! "$LOG_TO_STD" ]; then
                tail -n 3000 "${CROSS_LOG_FILE}"
                echo "full build log: ${CROSS_LOG_FILE}"
            fi
            echo "build cross ${DIST_NAME_PREFIX}${TARGET} error"
            exit 1
        else
            echo "build cross ${DIST_NAME_PREFIX}${TARGET} success"
        fi
    fi

    if [ "$NATIVE_BUILD" ]; then
        echo "build native ${DIST_NAME_PREFIX}${TARGET} to ${NATIVE_DIST_NAME}"
        rm -rf "${NATIVE_DIST_NAME}" "${NATIVE_LOG_FILE}"
        $MAKE clean
        {
            OUTPUT="${NATIVE_DIST_NAME}"
            NATIVE="true"
        }
        WriteConfig
        while IFS= read -r line; do
            CURRENT_DATE=$(Date)
            if [ "$LOG_TO_STD" ]; then
                echo "[$CURRENT_DATE] ${DIST_NAME_PREFIX}${TARGET}-native: $line"
            fi
            if [ ! "$DISABLE_LOG_TO_FILE" ]; then
                echo "[$CURRENT_DATE] $line" >>"${NATIVE_LOG_FILE}"
            fi
        done < <(
            set +e
            PATH="${CROSS_DIST_NAME}/bin:${PATH}" \
                $MAKE install 2>&1
            echo $? >"${NATIVE_DIST_NAME}.exit"
        )
        read EXIT_CODE <"${NATIVE_DIST_NAME}.exit"
        rm "${NATIVE_DIST_NAME}.exit"
        if [ $EXIT_CODE -ne 0 ]; then
            if [ ! "$LOG_TO_STD" ]; then
                tail -n 3000 "${NATIVE_LOG_FILE}"
                echo "full build log: ${NATIVE_LOG_FILE}"
            fi
            echo "build native ${DIST_NAME_PREFIX}${TARGET} error"
            exit 1
        else
            echo "build native ${DIST_NAME_PREFIX}${TARGET} success"
        fi
    fi
    if [ "$TEST_BUILD_ONLY" ]; then
        rm -rf "${CROSS_DIST_NAME}" "${NATIVE_DIST_NAME}"
    elif [ "$ENABLE_ARCHIVE" ]; then
        tar -zcf "${CROSS_DIST_NAME}.tgz" -C "${CROSS_DIST_NAME}" .
        echo "package ${CROSS_DIST_NAME} to ${CROSS_DIST_NAME}.tgz success"

        if [ "$NATIVE_BUILD" ]; then
            tar -zcf "${NATIVE_DIST_NAME}.tgz" -C "${NATIVE_DIST_NAME}" .
            echo "package ${NATIVE_DIST_NAME} to ${NATIVE_DIST_NAME}.tgz success"
        fi
        rm -rf "${CROSS_DIST_NAME}" "${NATIVE_DIST_NAME}"
    fi
}

ALL_TARGETS='aarch64-linux-musl
arm-linux-musleabi
arm-linux-musleabihf
armv5-linux-musleabi
armv5-linux-musleabihf
armv6-linux-musleabi
armv6-linux-musleabihf
armv7-linux-musleabi
armv7-linux-musleabihf
i486-linux-musl
i686-linux-musl
mips-linux-musl
mips-linux-musln32
mips-linux-muslsf
mips-linux-musln32sf
mipsel-linux-musl
mipsel-linux-musln32
mipsel-linux-muslsf
mipsel-linux-musln32sf
mips64-linux-musl
mips64-linux-musln32
mips64-linux-musln32sf
mips64el-linux-musl
mips64el-linux-musln32
mips64el-linux-musln32sf
powerpc-linux-musl
powerpc-linux-muslsf
powerpcle-linux-musl
powerpcle-linux-muslsf
powerpc64-linux-musl
powerpc64le-linux-musl
riscv64-linux-musl
s390x-linux-musl
x86_64-linux-musl
x86_64-linux-muslx32
i486-w64-mingw32
i686-w64-mingw32
x86_64-w64-mingw32'

function BuildAll() {
    if [ "$TARGETS_FILE" ]; then
        if [ -f "$TARGETS_FILE" ]; then
            while read line; do
                if [ -z "$line" ] || [ "${line:0:1}" == "#" ]; then
                    continue
                fi
                Build "$line"
            done <"$TARGETS_FILE"
            return
        else
            TARGETS="$TARGETS_FILE"
        fi
    else
        TARGETS="$ALL_TARGETS"
    fi

    for line in $TARGETS; do
        if [ -z "$line" ] || [ "${line:0:1}" == "#" ]; then
            continue
        fi
        Build "$line"
    done
}

ChToScriptFileDir
Init
ParseArgs "$@"
FixArgs
BuildAll
