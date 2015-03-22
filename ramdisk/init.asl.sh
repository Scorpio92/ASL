#!/sbin/sh

ENABLED=$(cat /proc/asl/enabled)

ORIG_COUNT=$(cat /proc/asl/files_count)

if [ "$ENABLED" == "1" ]
 then

    ORIG_COUNT=$(cat /proc/asl/files_count)

    CALC_COUNT_FILES=$(find /system -type f | wc -l)

    CALC_COUNT_SYMLINKS=$(find /system -type l | wc -l)

    CALC_COUNT=$(($CALC_COUNT_FILES+$CALC_COUNT_SYMLINKS))

    if [ "$ORIG_COUNT" == "$CALC_COUNT" ]
     then

       touch /dev/asl/asl_list

       touch /dev/asl/root_hash

       for FILE in `find /system -type f -o -type l`
       do
       SUM_STRING="$SUM_STRING\n$(sha1sum $FILE)"
       done

       echo -e $SUM_STRING | sed '1d' > /dev/asl/asl_list

       sha1sum '/dev/asl/asl_list' > /dev/asl/root_hash

       ORIG_SUM=$(cat /proc/asl/root_hash)

       CALC_SUM=$(cat /dev/asl/root_hash | cut -b 1-40)

       if [ "$CALC_SUM" == "$ORIG_SUM" ]
        then
          echo '1' > /proc/asl/status
        else
          echo '0' > /proc/asl/status
          reboot recovery
       fi
    else
       echo '0' > /proc/asl/status
       reboot recovery
    fi
 else
   echo '0' > /proc/asl/status
fi
