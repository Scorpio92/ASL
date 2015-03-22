# ASL
Android Security List - Simple Secure Boot Mechanism

1.Edit config of your kernel, add CONFIG_ASL=y

CONFIG_ASL - enable Proc Interface in Kernel for ASL check in Ramdisk

CONFIG_ASL_DISABLED - not set it, if you want enable ASL

2.Edit your Ramdisk. Find init.<hardware>.rc script and edit him. 
Find "on fs" section and after all mount points, add "import init.asl.rc". 
For example:

on fs

    mount ext4 /dev/block/mmcblk0p2 /system rw wait
    
    mount ext4 /dev/block/mmcblk0p3 /data nosuid nodev noatime wait usedm discard,noauto_da_alloc,nodelalloc
    
    mount ext4 /dev/block/mmcblk0p4 /cache wait nosuid nodev noatime nomblk_io_submit
    
    import init.asl.rc


Add need files from /sbin dir. in your ramdisk (busybox and hims symlinks)

3.Edit device.mk file in Android sources, add:

PRODUCT_COPY_FILES += \

device/.../.../ramdisk/init.asl.sh:root/init.asl.sh \

device/.../.../ramdisk/init.asl.rc:root/init.asl.rc

4.Integrate ASL in Android sources. See commit №2.

5.Build your favorite ROM from sources with ASL support it!
