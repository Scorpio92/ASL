#********VARS*******************************************************
OUT_DIR=$1

SYSTEM_DIR=$1/system

KERNEL_OUT=$1/obj/KERNEL_OBJ

KERNEL_DIR=$2

LEN_OUT_DIR=$(echo $OUT_DIR | wc -m)

CUT_LEN=$[44+$LEN_OUT_DIR-2]

N="\\n"

KOV='"'
#********VARS END***************************************************

#********CLEAR WORKSPACE********************************************
echo -e "PREPARE TO CREATE ASL FILES...\n"

rm $OUT_DIR/asl_list

rm $OUT_DIR/asl_img_hash

rm $OUT_DIR/files_count

rm $OUT_DIR/permissions

rm $OUT_DIR/asl.img

rm $OUT_DIR/data/asl/asl.img

touch $OUT_DIR/asl_list

touch $OUT_DIR/asl_img_hash

touch $OUT_DIR/files_count

touch $OUT_DIR/permissions
#********CLEAR END**************************************************

#********ASL_LIST***************************************************
echo -e "CREATING ASL LIST...\n"
for FILE in `find $SYSTEM_DIR -type f -o -type l | busybox sort -f`
  do

  echo -e "$(sha1sum $FILE)\n"

  SHA1="$(sha1sum $FILE)"

  SUM_STRING=$KOV$SHA1$N$KOV

  echo "$SUM_STRING" | cut --complement -b 44-$CUT_LEN >> $OUT_DIR/asl_list
done
#********ASL_LIST END***********************************************

#********CALC FILES_COUNT*******************************************
echo -e "CALCULATING FILES COUNT...\n"
COUNT=$(find $SYSTEM_DIR -type f -o -type l | wc -l)

echo -e "COUNT OF THE SYSTEM FILES IS : "$COUNT"\n"

echo '"'$COUNT'"' > $OUT_DIR/files_count
#********CALC FILES_COUNT END***************************************

#********SET PERMISSIONS AND UID/GID********************************
echo -e "SETTING PERMISSIONS AND CREATING PERMISSION MANIFEST...\n"

cat $OUT_DIR/asl_permissions.conf | 
(while read line
do

ARGS=$(echo $line | awk -F ", " '{print}' | wc -w)

#FILE
if [ $ARGS == 4 ]
then

vUID=$(echo $line | awk -F ", " '{print $1}')

vGUID=$(echo $line | awk -F ", " '{print $2}')

MODE=$(echo $line | awk -F ", " '{print $3}')

FILE=$(echo $line | awk -F ", " '{print $4}')

chown $vUID:$vGUID $OUT_DIR$FILE

chmod $MODE $OUT_DIR$FILE
fi

#DIR
if [ $ARGS == 5 ]
then

vUID=$(echo $line | awk -F ", " '{print $1}')

vGUID=$(echo $line | awk -F ", " '{print $2}')

DIRMODE=$(echo $line | awk -F ", " '{print $3}')

FILEMODE=$(echo $line | awk -F ", " '{print $4}')

DIR=$(echo $line | awk -F ", " '{print $5}')

find $OUT_DIR$DIR -type f -exec chown $vUID:$vGUID {} \;

find $OUT_DIR$DIR -type d -exec chown $vUID:$vGUID {} \;

find $OUT_DIR$DIR -type d -exec chmod $DIRMODE {} \;

find $OUT_DIR$DIR -type f -exec chmod $FILEMODE {} \;

fi

PERM_STRING=$KOV$line$N$KOV

echo "$PERM_STRING" >> $OUT_DIR/permissions

done
)
#********SET PERMISSIONS AND UID/GID END****************************

#********ASL.IMG BUILD**********************************************
echo -e "BUILDING ASL RECOVERY IMAGE...\n"

TEMP=$(find $SYSTEM_DIR -maxdepth 0 -type d -exec du -hsLl {} \;)

SIZE=${TEMP:0:3}

#./make_ext4fs -l $SIZE"M" -a system $OUT_DIR/asl.img $SYSTEM_DIR

dd if=/dev/zero of=$OUT_DIR/asl.img bs=1M count=$SIZE

mkfs ext4 -F $OUT_DIR/asl.img

mkdir $OUT_DIR/asl_img

mount -o loop,rw $OUT_DIR/asl.img $OUT_DIR/asl_img

cp -R $SYSTEM_DIR/* $OUT_DIR/asl_img/

umount $OUT_DIR/asl_img

rm -d $OUT_DIR/asl_img

TEMP=$(echo "$(sha1sum $OUT_DIR/asl.img)" | awk -F " " '{print $1}')

echo '"'$TEMP'"' > $OUT_DIR/asl_img_hash

echo -e "ROOT HASH OF THE ASL.IMG IS : "$(cat $OUT_DIR/asl_img_hash)"\n"
#********ASL.IMG BUILD END******************************************

#********COPY ASL.IMG TO USERDATA***********************************
mkdir -p $OUT_DIR/data/asl

cp $OUT_DIR/asl.img $OUT_DIR/data/asl/asl.img
#********COPY ASL.IMG TO USERDATA END*******************************

#********CLEAR TEMP KERNEL FILES************************************
echo -e "PREPARE KERNEL SOURCES FOR RE-BUILD WITH NEW ASL FILES...\n"

rm $OUT_DIR/kernel

rm $KERNEL_OUT/security/asl/*.o

rm $KERNEL_OUT/arch/arm/boot/zImage

rm $KERNEL_DIR/security/asl/list

rm $KERNEL_DIR/security/asl/files_count

rm $KERNEL_DIR/security/asl/asl_img_hash

rm $KERNEL_DIR/security/asl/permissions
#********CLEAR TEMP KERNEL FILES END********************************

#********COPY ASL FILES TO KERNEL SOURCES***************************
echo -e "COPY ASL FILES TO KERNEL SOURCES...\n"

cp $OUT_DIR/asl_img_hash $KERNEL_DIR/security/asl/asl_img_hash

cp $OUT_DIR/asl_list $KERNEL_DIR/security/asl/list

cp $OUT_DIR/files_count $KERNEL_DIR/security/asl/files_count

cp $OUT_DIR/permissions $KERNEL_DIR/security/asl/permissions
#********COPY ASL FILES TO KERNEL SOURCES END***********************

#********COPY BUSYBOX AND SYMLINKS TO RAMDISK SBIN******************
cp $(pwd)/build/core/asl/ramdisk/sbin/busybox $OUT_DIR/root/sbin/busybox

cp -d $(pwd)/build/core/asl/ramdisk/sbin/* $OUT_DIR/root/sbin
#********COPY BUSYBOX AND SYMLINKS TO RAMDISK SBIN END**************


