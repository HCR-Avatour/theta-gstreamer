# Build an Nvidia Deepstream image with GStreamer 1.22 (needs to be built from source)
FROM nvcr.io/nvidia/deepstream:6.4-samples-multiarch AS nv-gst-1.22
# Remove old GStreamer
RUN apt-get remove -y *gstreamer*
# Install build dependencies
RUN <<-EOF
    apt-get update
    apt-get install -y python3-pip libdrm-dev libmount-dev flex bison libglib2.0-dev
    pip3 install meson ninja
EOF
# Install audio system so that audio plugins will build
RUN apt-get install -y alsa-base libasound2-dev
# Build GStreamer from source
RUN <<-EOF
    # Download sources
    mkdir /tmp/gst-build
    cd /tmp/gst-build
    git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git .
    git checkout 1.22.10
    # Build GStreamer
    meson build --prefix=/usr
    ninja -C build/
    cd build/ && ninja install
    # Clean up
    cd / && rm -rf /tmp/gst-build
EOF

# Establish Base for Building Plugins
FROM ubuntu:rolling AS build_base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN ln -sf /usr/lib/$(uname -m)-linux-gnu /usr/lib/platform
WORKDIR /build
# Install Basic Build Tools
RUN apt-get install -y build-essential pkg-config git cmake
# Install libuvc build dependencies
RUN apt-get install -y libusb-1.0.0-dev
# Install GStreamer plugin build dependencies
RUN apt-get install -y libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev

# Build modified libuvc
# Produces /usr/local/lib/libuvc.so*
FROM build_base AS libuvc
RUN git clone https://github.com/ricohapi/libuvc-theta .
RUN git remote add upstream https://github.com/libuvc/libuvc && git fetch upstream
RUN git checkout v0.0.7 && git -c user.name=bogus -c user.email=lie@example.com cherry-pick 092cf64c2c942a2fa985f56cb5f69e7407141a2f
RUN cmake .
RUN make install

# Build gstthetauvc
# Produces /usr/lib/platform/gstreamer-1.0/gstthetauvc.so
FROM build_base AS gstthetauvc
RUN git clone https://github.com/nickel110/gstthetauvc .
COPY --from=libuvc /usr/local/lib/libuvc.so* /usr/local/lib/
COPY --from=libuvc /usr/local/include/libuvc/ /usr/local/include/libuvc/
COPY --from=libuvc /usr/local/lib/pkgconfig/libuvc.pc /usr/local/lib/pkgconfig/
RUN cd thetauvc && make
RUN cp thetauvc/gstthetauvc.so /usr/lib/platform/gstreamer-1.0/

# Build final image
FROM nv-gst-1.22 AS final
RUN ln -sf /usr/lib/$(uname -m)-linux-gnu /usr/lib/platform

# Install Theta Plugins
COPY --from=libuvc /usr/local/lib/libuvc.so.0.0.7 /usr/lib/platform/
RUN ln -sf libuvc.so.0.0.7 /usr/lib/platform/libuvc.so.0
RUN ln -sf libuvc.so.0 /usr/lib/platform/libuvc.so 
COPY --from=gstthetauvc /usr/lib/platform/gstreamer-1.0/gstthetauvc.so /usr/lib/platform/gstreamer-1.0/

# Install entrypoint script
COPY entrypoint.sh /bin/entrypoint
CMD ["entrypoint"]
