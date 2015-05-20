#********************VARS****************************************************************************************************************
SYSTEM_DIR="/home/scorpio92/ASL_Test/system"

KERNEL_DIR="/home/scorpio92/kernels/c8690-jb-4.1"

TARGET_ARCH="arm"

KERNEL_CONFIG="Exynos4Brothers_newman_stable_defconfig"

COMPILER_PATH="/home/scorpio92/Compilers/toolchains-master/arm-unknown-linux-gnueabi-linaro_4.7.4-2013.11/bin/arm-unknown-linux-gnueabi-"

KERNEL_BIN_PATH="arch/arm/boot"

KERNEL_TYPE="zImage"

KERNEL_MODULES_PATH=$SYSTEM_DIR/lib/modules

OUT_DIR=$(pwd)/OUT
#****************************************************************************************************************************************

#******************RUN BILD SCRIPT*******************************************************************************************************
./asl.sh $SYSTEM_DIR $KERNEL_DIR $TARGET_ARCH $KERNEL_CONFIG $COMPILER_PATH $KERNEL_BIN_PATH $KERNEL_TYPE $KERNEL_MODULES_PATH $OUT_DIR
#****************************************************************************************************************************************
