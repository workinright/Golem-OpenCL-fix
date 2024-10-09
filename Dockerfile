# a Dockerfile to build nvidia-files.squashfs and initramfs_new.cpio.gz with nvidia drivers kernel modules and shared libraries
FROM debian:stable AS build

ENV Linux_kernel_release="v6.x"
ENV Linux_kernel_version="6.1.66"
ENV NVIDIA_driver_pack_version="535.183.01"


RUN apt-get update && \
   apt-get -y install \
      wget pixz \
      build-essential kmod \
      bc flex bison libelf-dev libssl-dev rsync \
      squashfs-tools cpio pigz \
   && apt-get clean

RUN wget "https://download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_driver_pack_version}/NVIDIA-Linux-x86_64-${NVIDIA_driver_pack_version}-no-compat32.run" \
   && chmod +x NVIDIA-Linux-x86_64-535.183.01-no-compat32.run

RUN wget "https://mirrors.edge.kernel.org/pub/linux/kernel/${Linux_kernel_release}/linux-${Linux_kernel_version}.tar.xz"

RUN ./NVIDIA-Linux-x86_64-${NVIDIA_driver_pack_version}-no-compat32.run -x && rm NVIDIA-Linux-x86_64-${NVIDIA_driver_pack_version}-no-compat32.run

RUN pixz -d linux-${Linux_kernel_version}.tar.xz && tar xf linux-${Linux_kernel_version}.tar && rm linux-${Linux_kernel_version}.tar


# important - their config-6.1.66 seems to not be complete, but using olddefconfig instead of oldconfig works the problem around
COPY config-${Linux_kernel_version} /linux-${Linux_kernel_version}/.config
RUN cd linux-${Linux_kernel_version} && make olddefconfig && make -j$(nproc) prepare
RUN cd linux-${Linux_kernel_version} && make -j$(nproc) modules
RUN cd linux-${Linux_kernel_version} && make modules_install


RUN rsync -a --info=progress2 -m --exclude=/dev -m --exclude=/proc -m --exclude=/sys -m --exclude=/state1 -m / /state1 --delete --delete-excluded

RUN NVIDIA-Linux-x86_64-${NVIDIA_driver_pack_version}-no-compat32/nvidia-installer -q --ui=none -k "${}" --kernel-source-path=/linux-${Linux_kernel_version} \
   && rm -rf linux-${Linux_kernel_version}

RUN rsync -a --info=progress2 -m --exclude=/dev -m --exclude=/proc -m --exclude=/sys -m --exclude=/state1 -m --exclude=/diff_output -m --compare-dest=/state1 -m / /diff_output --delete --delete-excluded \
   && find /diff_output -type d -empty -exec rmdir -p --ignore-fail-on-non-empty {} + 2>/dev/null || true \
   && find /diff_output -type d -empty -exec rmdir -p --ignore-fail-on-non-empty {} + 2>/dev/null || true \
   && rm -rf /state1

RUN mksquashfs /diff_output nvidia-files.squashfs


COPY "initramfs_org.cpio.gz" /initramfs_org.cpio.gz

RUN mkdir initramfs_unpack && cd initramfs_unpack && pigz -d -c /initramfs_org.cpio.gz | cpio -id

RUN cd initramfs_unpack && find . -name '*.ko' | while read line; \
   do path="$(find /lib/modules/6.1.66 -name "$(basename "$line")" | head -n1)"; \
   if ! [ -z "$path" ]; then if [ -f "$path" ]; then echo "$path"; cp "$path" .; fi; fi; \
done

RUN cd initramfs_unpack && find . | cpio --quiet --dereference -o -H newc | pigz > /initramfs_new.cpio.gz


# now run
#
#
#   docker cp $(docker create ker):/nvidia-files.squashfs . && docker cp $(docker create ker):/initramfs_new.cpio.gz .
#
#
# to get the resulting two files, which are the result of the whole build process
