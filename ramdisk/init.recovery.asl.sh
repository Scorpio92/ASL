#!/sbin/sh

#Create recovery archive from device with installed ROM
#1) Create system image
# dd if=/dev/block/mmcblk0p2 of=/mnt/sdcard/sysdd.img
#Create recovery archive in compilation process
# dd if=/dev/zero of=file.img bs=1M count=500
# mkfs ext4 -F file.img
# sudo mount -o loop,rw file.img 1
# sudo cp -R system/* 1/
# sudo umount 1
#2) Mount img
# losetup /dev/block/loop2 /mnt/sdcard/sysdd.img
# mount -t ext4 /dev/block/loop2 /mnt/udisk
# OR
# mount -o loop=/dev/block/loop0 -t ext4 /mnt/sdcard/sysdd.img /mnt/udisk

NEED_RECOVERY=$(cat /dev/asl/need_recovery)

ASL_IMAGE="/data/asl.img"

SD_MOUNT_POINT="/mnt/tmpsd"

ASL_MOUNT_POINT="/mnt/asl_img"

IMAGE_TYPE_FS="ext4"

SYS_DIR="/system"

ASL_LOOP="/dev/block/loop1"

SD_LOOP="/dev/block/loop2"


power_off()
{
umount $SD_MOUNT_POINT

reboot -p
}

mount_asl_img()
{
mkdir $ASL_MOUNT_POINT

losetup $ASL_LOOP $ASL_IMAGE

#mount img only in RO for save hash sum!
mount -o ro -t $IMAGE_TYPE_FS $ASL_LOOP $ASL_MOUNT_POINT

#mount -o loop=/dev/block/loop1 -t $IMAGE_TYPE_FS $ASL_IMAGE $ASL_MOUNT_POINT
}

mount_sd()
{
#how detect block device for sdcard
#1) adb shell mount, look 179:<number>
#2) cat /proc/partitions, look string </dev/block> with <number>

P1=$(cat /sdcard.conf | awk -F " " '{print $1}')

P2=$(cat /sdcard.conf | awk -F " " '{print $2}')

mkdir $SD_MOUNT_POINT

mount -o loop=$SD_LOOP -t $P1 $P2 $SD_MOUNT_POINT

#change path to the recovery imge
ASL_IMAGE=$SD_MOUNT_POINT"/asl.img"

if [ -f $ASL_IMAGE ]
then

  ORIG_SUM=$(cat /proc/asl/asl_img_hash)

  CALC_SUM=$(sha1sum $ASL_IMAGE | awk -F "  " '{print $1}')

  if [ $ORIG_SUM == $CALC_SUM ]	
  then

    mount_asl_img

    check_mod_files

    check_doa_files

    umount $ASL_MOUNT_POINT

  else
    power_off
  fi

else
  power_off
fi

umount $SD_MOUNT_POINT
}

check_asl_img()
{
if [ -f $ASL_IMAGE ]
then

  ORIG_SUM=$(cat /proc/asl/asl_img_hash)

  CALC_SUM=$(sha1sum $ASL_IMAGE | awk -F "  " '{print $1}')

  if [ $ORIG_SUM == $CALC_SUM ]
  then

    mount_asl_img

    check_mod_files

    check_doa_files

    umount $ASL_MOUNT_POINT

  else
    mount_sd
  fi

else
mount_sd
fi
}

recovery_modify()
{
cat /dev/asl/mod_detected | 
(
while read line
do

if [ -n "$line" ]
then

  P=$(echo $line | awk -F " /system" '{ print $2}')

  rm $SYS_DIR$P

  cp $ASL_MOUNT_POINT$P $SYS_DIR$P
fi

done
)
}

recovery_doa()
{
cat /dev/asl/doa_detected | 
(
while read line
do

if [ -n "$line" ]
then

  S=$(echo $line | awk -F " /" '{ print $1}')

  P=$(echo $line | awk -F " /system" '{ print $2}')

  if [ "$S" == "-" ]
  then
    cp $ASL_MOUNT_POINT$P $SYS_DIR$P
  fi

  if [ "$S" == "+" ]
  then
    rm $SYS_DIR$P
  fi

fi
done
)
}

check_mod_files()
{
#проверка модифицированных файлов
cat /dev/asl/mod_detected | 
(while read line
do

if [ -n "$line" ]
then

  recovery_modify

  break
fi

done
)
}

check_doa_files()
{
#проверка на удаленные или добавленные файлы
cat /dev/asl/doa_detected | 
(while read line
do

if [ -n "$line" ]
then

  recovery_doa

  break
fi

done
)
}

if [ "$NEED_RECOVERY" == "1" ]
then

  check_asl_img

fi

