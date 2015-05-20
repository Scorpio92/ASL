WHAT IS IT?

Android Security List - Simple Secure Boot Mechanism

It control integrity of the SYSTEM partition with SHA-1 algorithm supports on early init and recover files if they was modified or deleted.

For recovery purpose uses asl.img file. It file contains all original files from SYSTEM partition with right permissions.

If asl.img not found - device will be power off.

After boot, you can see ASL Protocol in ASL Monitor app.
********************************************************

HOW BUILD IT?

You need in Android souces (any version Android OS, but better - CyanogenMod 10 and above) ans ASL source code.

1. Download ASL sources: git clone https://github.com/Scorpio92/ASL.git -b "branch name"

2. Patch "build" directory from ASL downloaded dir. See commit №2. Dirs: external, system - not necessarily patch.

3. Patch kernel sources. Prepare kernel_defconfig, include this:

   CONFIG_ASL=y    

   CONFIG_VT=y

4. Setup device folder, add string in product.mk line:

   $(call inherit-product-if-exists, $(LOCAL_PATH)/asl.mk)
   
5. Prepare init.rc for your OS version. Add in top of file:

   import /init.asl.rc
   
6. Add string in product.mk lines:
   
   PRODUCT_COPY_FILES += \

          $(LOCAL_PATH)/asl/ramdisk/init.rc:root/init.rc

6. Setup BoardConfig, add:

   TARGET_PROVIDES_INIT_RC := true     

   TARGET_KERNEL_SOURCE := kernel   

   TARGET_KERNEL_CONFIG := kernel_defconfig

7. Edit asl/ramdisk/sdcard.conf file. Add block for your EXTERNAL SD Card and FS type. Mount parameters not necessarily change.

8. make your ROM

9. Flash ROM, copy asl.img to SD Card and (it will be better, to DATA partition). Power on your device, wait.

ALSO YOU CAN BUILD KERNEL AND ASL.IMG MANUALLY:

1) see AMB/run.sh for example and change VARS to YOUR.

2) cd AMB

3) su

4) ./run.sh

My device: Exynos4, CyanogenMod10, ~3900 files in SYSTEM partition. ASL checking + recover process take about 1 min 20 seconds.
