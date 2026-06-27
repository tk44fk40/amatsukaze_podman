#!/bin/bash
set -e

# ============================================================
# 作業ディレクトリへ移動
# ============================================================

TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TARGET_DIR"

# ============================================================
# クリーンアップ
# ============================================================

echo "=== 0. 環境を初期化中 ==="

dirs=(
  avs
  bat
  config
  data
  drcs
  JL
  logo
  profile
  input
  output
)

files=(
  compose.yml
  Dockerfile
)

for d in "${dirs[@]}"; do
  [ -e "$d" ] && rm -rf -- "$d"
done

for f in "${files[@]}"; do
  [ -e "$f" ] && rm -f -- "$f"
done

# ============================================================
# ディレクトリ作成
# ============================================================

echo "=== 1. ディレクトリ作成 ==="

mkdir -p "${dirs[@]}"

# ============================================================
# テンプレート配置
# ============================================================

echo "=== 2. テンプレート配置 ==="

wget -q \
  "https://raw.githubusercontent.com/rigaya/Amatsukaze/main/defaults/drcs/drcs_map.txt" \
  || wget -q \
  "https://raw.githubusercontent.com/rigaya/Amatsukaze/master/defaults/drcs/drcs_map.txt"

mv drcs_map.txt drcs/ 2>/dev/null || true

wget -q \
  "https://github.com/tobitti0/join_logo_scp/archive/refs/tags/Ver4.1.0_Linux.tar.gz" \
  -O JL.tar.gz

tar -xf JL.tar.gz

mv join_logo_scp-Ver4.1.0_Linux/JL/* ./JL/

rm -rf join_logo_scp-Ver4.1.0_Linux JL.tar.gz

# ============================================================
# compose.yml
# ============================================================

echo "=== 3. compose.yml 生成 ==="

cat << 'EOC' > compose.yml
services:
  amatsukaze:
    image: amatsukaze
    container_name: amatsukaze

    build:
      context: ./
      dockerfile: Dockerfile
      args:
        ENABLE_FASTER_WHISPER: "0"
        ENABLE_VCEENCC: "0"

    restart: always

    ports:
      - "32768:32768"
      - "32769:32769"

    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

    devices:
      - /dev/dri:/dev/dri
      - nvidia.com/gpu=all

    volumes:
      - ./avs:/app/avs:Z
      - ./bat:/app/bat:Z
      - ./config:/app/config:Z
      - ./data:/app/data:Z
      - ./drcs:/app/drcs:Z
      - ./JL:/app/JL:Z
      - ./logo:/app/logo:Z
      - ./profile:/app/profile:Z
      - ./input:/app/input:Z
      - ./output:/app/output:Z
      - /tmp:/tmp:Z
EOC

# ============================================================
# Dockerfile
# ============================================================

echo "=== 4. Dockerfile 生成 ==="

cat << 'EOD' > Dockerfile

# ============================================================
# Builder stage
# ============================================================

FROM ubuntu:22.04 AS builder

ARG UBUNTU_VERSION=22.04
ARG UBUNTU_NAME=jammy
ARG ARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ENV UBUNTU_NAME=${UBUNTU_NAME}
ENV ARCH=${ARCH}

ENV AVISYNTHCUDAFILTERS_VER=0.7.3
ENV AVISYNTH_VER=3.7.5

ENV YADIFMOD2_VER=0.2.8
ENV TIVTC_VER=v1.0.29
ENV NNEDI3_REV=a93dbaea9f0dfc3f6d496a3fe01466bc22dd3a88
ENV MASKTOOLS_REV=8291927bf6956981a6412d353da8ca39d49c9d3a
ENV MVTOOLS_VER=2.7.46
ENV RGTOOLS_VER=1.2

ENV GPAC_VER=v2.4.0
ENV LSMASH_REV=18a9ed25c7ff79a7f4f4bf850c345c72179b8998

ENV CHAPTER_EXE_REV=32880d45f088e574285a101e6a49b032bb04f6ea
ENV JOIN_LOGO_SCP_VER=Ver4.1.0_Linux

ENV FDK_AAC_REV=d8e6b1a3aa606c450241632b64b703f21ea31ce3
ENV FDKAAC_VER=v1.0.6

ENV TSREADEX_VER=master-240517
ENV PSISIARC_VER=master-230324
ENV B24TOVTT_VER=master-220402

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        build-essential \
        git \
        curl \
        wget \
        tzdata \
        p7zip-full \
        nasm \
        cmake \
        meson \
        ninja-build \
        pkg-config \
        autoconf \
        automake \
        libtool \
        openssl \
        zlib1g \
        zlib1g-dev \
        libssl-dev \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        gnupg \
        dirmngr \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget \
    https://github.com/rigaya/AviSynthCUDAFilters/releases/download/${AVISYNTHCUDAFILTERS_VER}/avisynth_${AVISYNTH_VER}-1_${ARCH}_Ubuntu${UBUNTU_VERSION}.deb \
    -O avisynth.deb \
    && apt-get update \
    && apt-get install -y ./avisynth.deb \
    && rm ./avisynth.deb

WORKDIR /tmp/plugins

RUN git clone --depth=1 --branch ${YADIFMOD2_VER} \
    https://github.com/Asd-g/yadifmod2 \
    && cd yadifmod2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

RUN git clone --depth=1 --branch ${TIVTC_VER} \
    https://github.com/pinterf/TIVTC \
    && cd TIVTC/src \
    && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -B build -S . \
    && cmake --build build -j$(nproc) \
    && cd build \
    && make install

RUN git clone -b avsp --single-branch \
    https://github.com/rigaya/NNEDI3.git \
    && cd NNEDI3 \
    && git checkout ${NNEDI3_REV} \
    && mkdir build \
    && cd build \
    && meson setup .. \
    && ninja \
    && ninja install

RUN git clone https://github.com/pinterf/masktools.git \
    && cd masktools \
    && git checkout ${MASKTOOLS_REV} \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

RUN git clone --depth=1 --branch ${MVTOOLS_VER} \
    https://github.com/pinterf/mvtools.git \
    && cd mvtools \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

RUN git clone --depth=1 --branch ${RGTOOLS_VER} \
    https://github.com/pinterf/RgTools.git \
    && cd RgTools \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

RUN git clone --depth=1 --branch ${GPAC_VER} \
    https://github.com/gpac/gpac.git \
    && cd gpac \
    && ./configure --static-bin \
    && make -j$(nproc) \
    && make install

RUN git clone https://github.com/l-smash/l-smash.git \
    && cd l-smash \
    && git checkout ${LSMASH_REV} \
    && ./configure \
    && make -j$(nproc) \
    && make install

RUN git clone https://github.com/rigaya/chapter_exe \
    && cd chapter_exe \
    && git checkout ${CHAPTER_EXE_REV} \
    && cd src \
    && make -j$(nproc) \
    && install -D -t /usr/local/bin chapter_exe

RUN git clone --depth=1 --branch ${JOIN_LOGO_SCP_VER} \
    https://github.com/tobitti0/join_logo_scp \
    && cd join_logo_scp/src \
    && make -j$(nproc) \
    && install -D -t /usr/local/bin join_logo_scp

RUN git clone https://github.com/mstorsjo/fdk-aac.git \
    && cd fdk-aac \
    && git checkout ${FDK_AAC_REV} \
    && ./autogen.sh \
    && ./configure --disable-shared --prefix=$(pwd)/fdk-aac-libs \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && git clone --depth=1 --branch ${FDKAAC_VER} \
    https://github.com/nu774/fdkaac.git \
    && cd fdkaac \
    && autoreconf -i \
    && PKG_CONFIG_PATH=../fdk-aac/fdk-aac-libs/lib/pkgconfig ./configure \
    && make -j$(nproc) \
    && make install

RUN git clone --depth=1 --branch ${TSREADEX_VER} \
    https://github.com/xtne6f/tsreadex.git \
    && cd tsreadex \
    && make -j$(nproc) \
    && install -D -t /usr/local/bin tsreadex

RUN git clone --depth=1 --branch ${PSISIARC_VER} \
    https://github.com/xtne6f/psisiarc.git \
    && cd psisiarc \
    && make -j$(nproc) \
    && install -D -t /usr/local/bin psisiarc

RUN git clone --depth=1 --branch ${B24TOVTT_VER} \
    https://github.com/xtne6f/b24tovtt.git \
    && cd b24tovtt \
    && make -j$(nproc) \
    && install -D -t /usr/local/bin b24tovtt

RUN rm -rf /tmp/plugins

# ============================================================
# Runtime stage
# ============================================================

FROM nvidia/cuda:12.6.3-base-ubuntu22.04 AS runtime

ARG UBUNTU_VERSION=22.04
ARG UBUNTU_NAME=jammy
ARG ARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

ENV QSVENCC_VER=8.17
ENV NVENCC_VER=9.20
ENV TSREPLACE_VER=0.19

ENV AVISYNTHCUDAFILTERS_VER=0.7.3
ENV AVISYNTH_VER=3.7.5

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        gpg \
        gnupg \
        dirmngr \
        ca-certificates \
        curl \
        wget \
        tzdata \
        software-properties-common \
        p7zip-full \
        git \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        xz-utils \
        locales \
        openssl \
        zlib1g \
        zlib1g-dev \
        mkvtoolnix \
        opus-tools \
        libva-drm2 \
        libva-x11-2 \
        ocl-icd-opencl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key \
    | gpg --yes --dearmor \
      --output /usr/share/keyrings/intel-graphics.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu ${UBUNTU_NAME} unified" \
      > /etc/apt/sources.list.d/intel-gpu.list \
    && apt-get update \
    && apt-get install -y \
        intel-media-va-driver-non-free \
        intel-opencl-icd \
        libigfxcmrt7 \
        libmfx1 \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen ja_JP.UTF-8 \
    && update-locale LANG=ja_JP.UTF-8

RUN wget \
    https://github.com/rigaya/QSVEnc/releases/download/${QSVENCC_VER}/qsvencc_${QSVENCC_VER}_${ARCH}.deb \
    -O qsvencc.deb \
    && apt-get update \
    && apt-get install -y ./qsvencc.deb \
    && rm ./qsvencc.deb

RUN wget \
    https://github.com/rigaya/NVEnc/releases/download/${NVENCC_VER}/nvencc_${NVENCC_VER}_${ARCH}.deb \
    -O nvencc.deb \
    && apt-get update \
    && apt-get install -y ./nvencc.deb \
    && rm ./nvencc.deb

RUN wget \
    https://github.com/rigaya/tsreplace/releases/download/${TSREPLACE_VER}/tsreplace_${TSREPLACE_VER}_${ARCH}.deb \
    -O tsreplace.deb \
    && apt-get update \
    && apt-get install -y ./tsreplace.deb \
    && rm ./tsreplace.deb

RUN wget \
    https://github.com/rigaya/AviSynthCUDAFilters/releases/download/${AVISYNTHCUDAFILTERS_VER}/avisynth_${AVISYNTH_VER}-1_${ARCH}_Ubuntu${UBUNTU_VERSION}.deb \
    -O avisynth.deb \
    && apt-get update \
    && apt-get install -y ./avisynth.deb \
    && rm ./avisynth.deb

RUN wget \
    https://github.com/rigaya/AviSynthCUDAFilters/releases/download/${AVISYNTHCUDAFILTERS_VER}/avisynthcudafilters_${AVISYNTHCUDAFILTERS_VER}-1_${ARCH}_Ubuntu${UBUNTU_VERSION}.deb \
    -O avisynthcudafilters.deb \
    && apt-get update \
    && apt-get install -y ./avisynthcudafilters.deb \
    && rm ./avisynthcudafilters.deb

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

WORKDIR /app

RUN mkdir -p \
    /app/avs \
    /app/bat \
    /app/config \
    /app/data \
    /app/drcs \
    /app/JL \
    /app/logo \
    /app/profile \
    /app/input \
    /app/output \
    /app/temp \
    /app/exe_files/plugins64

RUN git clone --depth 1 -b 0.04 \
    https://github.com/rigaya/SCRenamePy.git \
    tmp_SCRenamePy \
    && mkdir -p exe_files/SCRenamePy \
    && mv tmp_SCRenamePy/SCRename.* exe_files/SCRenamePy/ \
    && rm -rf tmp_SCRenamePy

COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu

RUN curl -s \
    https://api.github.com/repos/rigaya/Amatsukaze/releases/latest \
    | grep "browser_download_url.*tar.xz" \
    | grep "Ubuntu${UBUNTU_VERSION}" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -i - -O - \
    | tar -xJ -C /app \
    && if [ -f /app/scripts/install.sh ]; then \
         /app/scripts/install.sh; \
       fi

RUN cat <<'EOE' > /app/entrypoint.sh
#!/bin/bash
set -e
umask 022
exec "$@"
EOE

RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

CMD ["./AmatsukazeServer.sh"]

EOD

echo "================================================"
echo "✅ setup 完了"
echo "================================================"

echo
echo "次:"
echo "  podman compose build --no-cache"
echo