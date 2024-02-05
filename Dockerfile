FROM ubuntu:rolling AS base
# Prevent apt from asking for user input
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN ln -sf /usr/lib/$(uname -m)-linux-gnu /usr/lib/platform/

FROM base AS build_base
WORKDIR /build

# Basic Build Tools
RUN apt-get install -y build-essential pkg-config git cmake
# libuvc build dependencies
RUN apt-get install -y libusb-1.0.0-dev # libjpeg-turbo8-dev
# GStreamer plugin build dependencies
RUN apt-get install -y libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev

# Build modified libuvc
# Produces /usr/lib/platform/libuvc.so*
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

# Build simple-whip-client
# Produces /usr/local/bin/whip-client
# FROM build_base AS simple-whip-client
# RUN apt-get install -y libjson-glib-dev libsoup2.4-dev
# RUN git clone https://github.com/meetecho/simple-whip-client .
# RUN make
# RUN cp whip-client /usr/local/bin

# Build rswebrtc
# Produces /usr/lib/platform/gstreamer-1.0/libgstrswebrtc.so
# Produces /usr/lib/platform/gstreamer-1.0/libgstrsrtp.so
# FROM build_base AS rswebrtc
# RUN apt-get install -y cargo libssl-dev libglib2.0-dev
# RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs .
# RUN git checkout 0.11.3+fixup
# RUN cd net/webrtc && cargo build --release
# RUN cd net/rtp && cargo build --release
# RUN cd target/release && strip libgstrswebrtc.so && strip libgstrsrtp.so
# RUN cp target/release/*.so /usr/lib/platform/gstreamer-1.0/

# Build final image
FROM base AS final

# Install GStreamer
RUN apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-rtsp

# Install Theta Plugins
COPY --from=libuvc /usr/lib/platform/libuvc.so.0.0.7 /usr/lib/platform/
RUN ln -sf libuvc.so.0.0.7 /usr/lib/platform/libuvc.so.0
RUN ln -sf libuvc.so.0 /usr/lib/platform/libuvc.so 
COPY --from=gstthetauvc /usr/lib/platform/gstreamer-1.0/gstthetauvc.so /usr/lib/platform/gstreamer-1.0/

# Install WebRTC Plugins
# COPY --from=rswebrtc /usr/lib/platform/gstreamer-1.0/libgstrswebrtc.so /usr/lib/platform/gstreamer-1.0/
# COPY --from=rswebrtc /usr/lib/platform/gstreamer-1.0/libgstrsrtp.so /usr/lib/platform/gstreamer-1.0/
#COPY --from=simple-whip-client /usr/local/bin/whip-client /usr/local/bin

# Install entrypoint script
COPY entrypoint.sh /bin/entrypoint
CMD ["entrypoint"]

# ln -s /usr/local/lib/libuvc.so.0 /usr/lib/aarch64-linux-gnu/libuvc.so.0
