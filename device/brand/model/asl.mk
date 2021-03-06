#ASL Makefile
LOCAL_PATH := device/brand/model

# ASL permissions manifest
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/asl/asl_permissions.conf:asl_permissions.conf

# ASL ramdisk files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/asl/ramdisk/init.asl.rc:root/init.asl.rc \
    $(LOCAL_PATH)/asl/ramdisk/sdcard.conf:root/sdcard.conf \
    $(LOCAL_PATH)/asl/ramdisk/init.asl.sh:root/init.asl.sh \
    $(LOCAL_PATH)/asl/ramdisk/init.recovery.asl.sh:root/init.recovery.asl.sh

# ASL Monitor app
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/asl/asl_monitor.apk:system/app/asl_monitor.apk
 

