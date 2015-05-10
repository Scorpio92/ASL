#!/sbin/sh

ENABLED=""

TERM="/dev/tty0"

N="\n\n\n\n\n"

SLEEP_TIME="1s"


init()
{
if [ -f "/proc/asl/enabled" ]
 then
  ENABLED=$(cat /proc/asl/enabled)
 else
  exit 0
fi

if [ "$ENABLED" == "1" ]
then
  
  VERSION=$(cat /proc/asl/version)
 
  echo -e $N"A N D R O I D   S E C U R I T Y   L I S T   v"$VERSION > $TERM

  echo -e "\n\nA U T H O R   I S   S C O R P I O 9 2" > $TERM

  sleep 3s

  echo -e $N"S T A R T I N G . . ." > $TERM

  sleep $SLEEP_TIME
       
  sha1check

  proto_parse

  check_count

  echo '0' > /dev/asl/need_recovery

  check_status

else
  echo '0' > /proc/asl/status

  echo '0' > /dev/asl/need_recovery

  exit 0
fi
}

sha1check() 
{
cp /proc/asl/list /dev/asl/asl_list

echo -e $N"S H A - 1   S U M   C H E C K I N G . . ." > $TERM

echo "$(sha1sum -c '/dev/asl/asl_list')" > /dev/asl/asl_protocol

echo -e $N"S H A - 1   S U M   C H E C K I N G   C O M P L E T E D" > $TERM

sleep $SLEEP_TIME
}

proto_parse()
{
echo -e $N"A S L   P R O T O C O L   P A R S I N G . . ." > $TERM

sleep $SLEEP_TIME

cat /dev/asl/asl_protocol | grep "FAILED" | awk -F ":" '{print $1}' > /dev/asl/failed_detected

cat /dev/asl/failed_detected | 
(while read line
do

if [ -n "$line" ]
 then

  echo -e $N"D E T E C T E D   B R O K E N   I N T E G R I T Y   ! ! !" > $TERM

  sleep $SLEEP_TIME

  break
fi

done
)

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

cat /dev/asl/mod_detected | 
(while read line
do

if [ -n "$line" ]
 then

  echo -e $N"D E T E C T E D   M O D I F I C A T I O N   ! ! !" > $TERM

  sleep $SLEEP_TIME

  break
fi

done
)
}

make_file_list()
{
echo "$(find /system -type f -o -type l | sort -f)" > /dev/asl/file_list

#протокол без статусов
cat /dev/asl/asl_protocol | sort -f | awk -F ":" '{print $1}' > /dev/asl/proto_no_stat
}

check_doa_files()
{
echo -e $N"C H E C K I N G   D E L E T E D   O R   A D D E D   F I L E S . . ." > $TERM

sleep $SLEEP_TIME

ADDED=$(grep -F -v -x -f /dev/asl/proto_no_stat /dev/asl/file_list | sed 's/\/system/+ \/system/')

DELETED=$(grep -F -v -x -f /dev/asl/file_list /dev/asl/proto_no_stat | sed 's/\/system/- \/system/')

DOA=$ADDED"\n"$DELETED

echo -e "$DOA" > /dev/asl/doa_detected

echo -e $N"C H E C K I N G   C O M P L E T E D" > $TERM

sleep $SLEEP_TIME
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

check_doa_files
fi
}

bad_status()
{
echo '0' > /proc/asl/status

echo '1' > /dev/asl/need_recovery

echo -e $N"S T A R T   R E C O V E R Y   M O D E . . ." > $TERM

sleep $SLEEP_TIME
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

  echo -e $N"B O O T I N G   C O N T I N U E . . ." > $TERM

  sleep $SLEEP_TIME
  fi

done
)
fi
}

init

