#!/sbin/sh

NEED_RECOVERY=$(cat /dev/asl/need_recovery)
ARCHIVE="/data/system.zip"

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
fi
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

