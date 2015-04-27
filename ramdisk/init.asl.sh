#!/sbin/sh

#общее время загрузки увеличивается на ~40c
ENABLED=$(cat /proc/asl/enabled)

sha1check() 
{
cp /proc/asl/list /dev/asl/asl_list

echo "$(sha1sum -c '/dev/asl/asl_list')" > /dev/asl/asl_protocol
}

proto_parse()
{
cat /dev/asl/asl_protocol | grep "FAILED" | awk -F ":" '{print $1}' > /dev/asl/failed_detected

#получение списка только модифицированных файлов
cat /dev/asl/failed_detected | 
(
STR=""
while read line
do

if [ -f "$line" ]
 then
  STR=$STR"\n""* "$line
fi

done

echo -e $STR > /dev/asl/mod_detected

sed -i '1d' /dev/asl/mod_detected
)
}

make_file_list()
{
echo "$(find /system -type f -o -type l | sort -f)" > /dev/asl/file_list

#протокол без статусов
cat /dev/asl/asl_protocol | sort -f | awk -F ":" '{print $1}' > /dev/asl/proto_no_stat
}

check_added_files()
{
ADDED=$(grep -F -v -x -f /dev/asl/proto_no_stat /dev/asl/file_list | sed 's/\/system/+ \/system/')

DELETED=$(grep -F -v -x -f /dev/asl/file_list /dev/asl/proto_no_stat | sed 's/\/system/- \/system/')

DOA=$ADDED"\n"$DELETED

echo -e "$DOA" > /dev/asl/doa_detected
}

check_count()
{
#оригинальное количество
ORIG_COUNT=$(cat /proc/asl/files_count)

#количество файлов на разделе в момент проверки
CALC_COUNT_ON_SYSTEM=$(find /system -type f -o -type l | wc -l)

#количество ненайденных файлов в протоколе = [ кол-во failed - кол-во модифицированных ]
CALC_COUNT_IN_PROTO_NOT_EXIST=$[$(cat /dev/asl/failed_detected | wc -l)-$(cat /dev/asl/mod_detected | wc -l)]

#количество найденных файлов в протоколе
CALC_EXIST_IN_PROTO=$[$ORIG_COUNT-$CALC_COUNT_IN_PROTO_NOT_EXIST]

#если количество подсчитанных файлов во время проверки не равняется кол-ву проверенных файлов кроме удаленных
#то составляем опись всех файлов и сравниваем протокол и полученную опись для выявления добавленных файлов
if [ $CALC_COUNT_ON_SYSTEM != $CALC_EXIST_IN_PROTO ]
then

make_file_list

check_added_files
fi
}

bad_status()
{
echo '0' > /proc/asl/status

echo '1' > /dev/asl/need_recovery
}

good_status()
{
echo '1' > /proc/asl/status

echo '0' > /dev/asl/need_recovery
}

check_status() 
{
#проверка модифицированных файлов
cat /dev/asl/mod_detected | 
(while read line
do

if [ -n "$line" ]
 then

  bad_status

  break
 else
  good_status
fi

done
)

NEED_RECOVERY=$(cat /dev/asl/need_recovery)

if [ "$NEED_RECOVERY" != "1" ]
then
#проверка на удаленные или добавленные файлы
  cat /dev/asl/doa_detected | 
  (while read line
  do

  if [ -n "$line" ]
  then
    bad_status
    break
  else
  good_status
  fi

done
)
fi
}

if [ "$ENABLED" == "1" ]
then
       
  sha1check

  proto_parse

  check_count

  echo '0' > /dev/asl/need_recovery

  check_status

else
  echo '0' > /proc/asl/status
  echo '0' > /dev/asl/need_recovery
fi
