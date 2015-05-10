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

SD_MOUNT_POINT="/tmpsd"

ASL_MOUNT_POINT="/asl_img"

IMAGE_TYPE_FS="ext4"

SYS_DIR="/system"

TERM="/dev/tty0"

N="\n\n\n\n\n"

SLEEP_TIME="1s"


power_off()
{
umount -l $SD_MOUNT_POINT

reboot -p

}

mount_asl_img()
{
echo -e $N"M O U N T I N G   R E C O V E R Y   I M A G E . . ." > $TERM

sleep $SLEEP_TIME

#mkdir $ASL_MOUNT_POINT

#free loop
ASL_LOOP=$(losetup -f)

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

#mount parameters
P1=$(cat /sdcard.conf | awk -F " " '{print $1}')
#fs type
P2=$(cat /sdcard.conf | awk -F " " '{print $2}')
#block device
P3=$(cat /sdcard.conf | awk -F " " '{print $3}')

#mkdir $SD_MOUNT_POINT
#mount -o $P1,loop=$SD_LOOP -t $P2 $P3 $SD_MOUNT_POINT
#mount -o $P1 -t $P2 $P3 $SD_MOUNT_POINT

echo -e $N"M O U N T I N G   S D   C A R D . . ." > $TERM

sleep $SLEEP_TIME

mount -t $P2 $P3 $SD_MOUNT_POINT

#change path to the recovery imge
ASL_IMAGE=$SD_MOUNT_POINT"/asl.img"

echo -e $N"F I N D I N G   R E C O V E R Y   I M A G E   O N   S D   C A R D . . ." > $TERM

sleep $SLEEP_TIME

if [ -f $ASL_IMAGE ]
then

  ORIG_SUM=$(cat /proc/asl/asl_img_hash)

  echo -e $N"C H E C K I N G   R E C O V E R Y   I M A G E   S H A - 1   S U M . . ." > $TERM

  sleep $SLEEP_TIME

  CALC_SUM=$(sha1sum $ASL_IMAGE | awk -F "  " '{print $1}')

  if [ $ORIG_SUM == $CALC_SUM ]	
  then

    mount_asl_img

    check_mod_files

    check_doa_files

    umount -l $ASL_MOUNT_POINT

  else
    echo -e $N"R E C O V E R Y   I M A G E   S H A - 1   S U M   F A I L E D   ! ! !" > $TERM

    sleep $SLEEP_TIME

    power_off
  fi

else
  echo -e $N"R E C O V E R Y   I M A G E   N O T   F O U N D   O N   S D   C A R D   ! ! !" > $TERM

  sleep $SLEEP_TIME

  power_off
fi

umount -l $SD_MOUNT_POINT
}

check_asl_img()
{
echo -e $N"F I N D I N G   R E C O V E R Y   I M A G E   I N   /D A T A . . ." > $TERM

sleep $SLEEP_TIME

if [ -f $ASL_IMAGE ]
then

  ORIG_SUM=$(cat /proc/asl/asl_img_hash)

  echo -e $N"C H E C K I N G   R E C O V E R Y   I M A G E   S H A - 1   S U M . . ." > $TERM

  sleep $SLEEP_TIME

  CALC_SUM=$(sha1sum $ASL_IMAGE | awk -F "  " '{print $1}')

  if [ $ORIG_SUM == $CALC_SUM ]
  then

    mount_asl_img

    check_mod_files

    check_doa_files

    umount -l $ASL_MOUNT_POINT

  else
    echo -e $N"R E C O V E R Y   I M A G E   S H A - 1   S U M   F A I L E D   ! ! !" > $TERM

    sleep $SLEEP_TIME

    mount_sd
  fi

else
  echo -e $N"R E C O V E R Y   I M A G E   N O T   F O U N D   I N   D A T A   ! ! !" > $TERM

  sleep $SLEEP_TIME

  mount_sd
fi
}

recovery_modify()
{
echo -e $N"R E C O V E R Y   M O D I F I E D   F I L E S . . ." > $TERM

sleep $SLEEP_TIME

cat /dev/asl/mod_detected | 
(
while read line
do

if [ -n "$line" ]
then

  P=$(echo $line | awk -F " /system" '{ print $2}')

  rm $SYS_DIR$P

  cp -d $ASL_MOUNT_POINT$P $SYS_DIR$P
fi

done
)

echo -e $N"C O M P L E T E D" > $TERM

sleep $SLEEP_TIME
}

recovery_doa()
{
echo -e $N"R E C O V E R Y   D E L E T E D   A N D   A D D E D   F I L E S . . ." > $TERM

sleep $SLEEP_TIME

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
    #if directory not exist
    DIR=$(dirname $SYS_DIR$P)

    if [ ! -d "$DIR" ]
    then

      mkdir -p "$DIR"

      chmod -R 755 $DIR
    fi
    cp -d $ASL_MOUNT_POINT$P $SYS_DIR$P
  fi

  if [ "$S" == "+" ]
  then
    rm $SYS_DIR$P
  fi

fi
done
)
echo -e $N"C O M P L E T E D" > $TERM

sleep $SLEEP_TIME
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

  echo -e $N"R E C O V E R Y   M O D E   I N I T E D" > $TERM

  sleep $SLEEP_TIME

  check_asl_img

  echo -e $N"R E C O V E R Y   C O M P L E T E D   ! ! !" > $TERM

  sleep $SLEEP_TIME

  echo -e $N"B O O T I N G   C O N T I N U E . . ." > $TERM

  sleep $SLEEP_TIME

fi

