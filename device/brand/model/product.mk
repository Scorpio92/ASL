#Product Makefile
LOCAL_PATH := device/brand/model

$(call inherit-product-if-exists, $(LOCAL_PATH)/asl.mk)

#ramdisk files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/asl/ramdisk/init.rc:root/init.rc
