#!/sbin/sh

NEED_RECOVERY=$(cat /dev/asl/need_recovery)

ARCHIVE="/data/system.zip"

power_off()
{
umount /mnt/tmpsd
repoot -p
}

mount_sd()
{
       #how detect block device for sdcard
       #1) adb shell mount, look 179:<number>
       #2) cat /proc/partitions, look string </dev/block> with <number>

       P1=$(cat /sdcard.conf | awk -F " " '{print $1}')

       P2=$(cat /sdcard.conf | awk -F " " '{print $2}')

       mkdir /mnt/tmpsd

       mount -r -t $P1 $P2 /mnt/tmpsd

       #change path to the archive
       ARCHIVE="/mnt/tmpsd/system.zip"

       if [ -f $ARCHIVE ]
       then

       ORIG_SUM=$(cat /proc/asl/archive_hash)

       CALC_SUM=$(sha1sum $ARCHIVE | awk -F "  " '{print $1}')

       if [ $ORIG_SUM == $CALC_SUM ]
       then

       unzip_archive

       check_mod_files

       check_doa_files

       else
       power_off
       fi

       else
       power_off
       fi

       umount /mnt/tmpsd
}

check_archive()
{
if [ -f $ARCHIVE ]
then
ORIG_SUM=$(cat /proc/asl/archive_hash)
CALC_SUM=$(sha1sum $ARCHIVE | awk -F "  " '{print $1}')
if [ $ORIG_SUM == $CALC_SUM ]
then
unzip_archive
check_mod_files
check_doa_files
else
mount_sd
fi
else
mount_sd
fi
}

unzip_archive()
{
unzip $ARCHIVE -d /dev/asl
}

recovery_modify()
{
cat /dev/asl/mod_detected | 
(
while read line
do
if [ -n "$line" ]
then
P=$(echo $line | awk -F " /" '{ print $2}')
rm /$P
cp /dev/asl/$P /$P
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
P=$(echo $line | awk -F " /" '{ print $2}')
if [ "$S" == "-" ]
then
cp /dev/asl/$P /$P
fi
if [ "$S" == "+" ]
then
rm /$P
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
check_archive
rm -rf /dev/asl/system
fi

