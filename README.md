
# NVIDIA Driver Builder for Golem Network Providers

This repository contains a Dockerfile used to build NVIDIA drivers in a specific format for Golem Network providers. The build process creates two key files:

1.  `nvidia-files.squashfs`: A SquashFS file containing NVIDIA driver files.
2.  `initramfs_new.cpio.gz`: A modified initial RAM filesystem with NVIDIA kernel modules.

## Usage

1.  Clone this repository:
    `git clone https://github.com/your-username/nvidia-golem-builder`
    `cd nvidia-golem-builder`
    
2.  Build the Docker image:
    `docker build -t nvidia-golem-builder .`
    
3.  Extract the built files:
    `docker cp $(docker create nvidia-golem-builder):/nvidia-files.squashfs .`
	`docker cp $(docker create nvidia-golem-builder):/initramfs_new.cpio.gz .`
    

## Customization

You can customize the build process by modifying the following environment variables in the Dockerfile:

-   `Linux_kernel_release`: The Linux kernel release (e.g., "v6.x")
-   `Linux_kernel_version`: The specific Linux kernel version (e.g., "6.1.66")
-   `NVIDIA_driver_pack_version`: The NVIDIA driver version (e.g., "535.183.01")
