#********VARS*******************************************************
SYSTEM_DIR=$1

KERNEL_DIR=$2

TARGET_ARCH=$3

KERNEL_CONFIG=$4

COMPILER_PATH=$5

KERNEL_BIN_PATH=$6

KERNEL_TYPE=$7

KERNEL_MODULES_PATH=$8

OUT_DIR=$9

KERNEL_OUT=$9/obj/KERNEL_OBJ

CONFIG_DIR=$(pwd)/config

PARENT_SYS_DIR=$(dirname $SYSTEM_DIR)

LEN_OUT_DIR=$(echo $PARENT_SYS_DIR | wc -m)

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

rm $OUT_DIR/kernel

rm -r $KERNEL_OUT

touch $OUT_DIR/asl_list

touch $OUT_DIR/asl_img_hash

touch $OUT_DIR/files_count

touch $OUT_DIR/permissions

mkdir -p $KERNEL_OUT
#********CLEAR END**************************************************

#***************BUILD KERNEL****************************************
echo -e "BUILD KERNEL WITH MODULES...\n"

./kernel_build.sh $KERNEL_DIR $KERNEL_OUT $TARGET_ARCH $KERNEL_BIN_PATH $KERNEL_TYPE $KERNEL_CONFIG $COMPILER_PATH $OUT_DIR "0"

rm $KERNEL_MODULES_PATH/*

find $KERNEL_OUT -name "*.ko" -exec cp {} $KERNEL_MODULES_PATH \;

#***************BUILD KERNEL END************************************

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

cat $CONFIG_DIR/asl_permissions.conf | 
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

chown $vUID:$vGUID $(dirname $SYSTEM_DIR)$FILE

chmod $MODE $(dirname $SYSTEM_DIR)$FILE
fi

#DIR
if [ $ARGS == 5 ]
then

vUID=$(echo $line | awk -F ", " '{print $1}')

vGUID=$(echo $line | awk -F ", " '{print $2}')

DIRMODE=$(echo $line | awk -F ", " '{print $3}')

FILEMODE=$(echo $line | awk -F ", " '{print $4}')

DIR=$(echo $line | awk -F ", " '{print $5}')

find $(dirname $SYSTEM_DIR)$DIR -type f -exec chown $vUID:$vGUID {} \;

find $(dirname $SYSTEM_DIR)$DIR -type d -exec chown $vUID:$vGUID {} \;

find $(dirname $SYSTEM_DIR)$DIR -type d -exec chmod $DIRMODE {} \;

find $(dirname $SYSTEM_DIR)$DIR -type f -exec chmod $FILEMODE {} \;

fi

PERM_STRING=$KOV$line$N$KOV

echo "$PERM_STRING" >> $OUT_DIR/permissions

done
)
#********SET PERMISSIONS AND UID/GID END****************************

#********ASL.IMG BUILD**********************************************
echo -e "BUILDING RECOVERY IMAGE...\n"

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

echo -e "ROOT HASH OF THE RECOVERY ARCHIVE IS : "$(cat $OUT_DIR/asl_img_hash)"\n"
#********ASL.IMG BUILD END******************************************

#********CLEAR TEMP KERNEL FILES************************************
echo -e "PREPARE KERNEL SOURCES FOR RE-BUILD WITH NEW ASL FILES...\n"

rm $KERNEL_OUT/security/asl/*.o

if [ $KERNEL_TYPE == "Image" ]
then
rm $KERNEL_OUT/$KERNEL_BIN_PATH/$KERNEL_TYPE
fi

if [ $KERNEL_TYPE == "zImage" ]
then
rm $KERNEL_OUT/$KERNEL_BIN_PATH/$KERNEL_TYPE
fi

if [ $KERNEL_TYPE == "uImage" ]
then
rm $KERNEL_OUT/$KERNEL_BIN_PATH/$KERNEL_TYPE
fi

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

#***************RE-BUILD KERNEL****************************************
echo -e "REBUILD KERNEL WITH ASL...\n"

./kernel_build.sh $KERNEL_DIR $KERNEL_OUT $TARGET_ARCH $KERNEL_BIN_PATH $KERNEL_TYPE $KERNEL_CONFIG $COMPILER_PATH $OUT_DIR "1"

echo -e "ALL DONE !!!\n"
#***************RE-BUILD KERNEL END************************************


