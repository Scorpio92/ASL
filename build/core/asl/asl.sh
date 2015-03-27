OUT_DIR=$1

SYSTEM_DIR=$1/system

KERNEL_OUT=$1/obj/KERNEL_OBJ

KERNEL_DIR=$2

rm $OUT_DIR/asl_list

rm $OUT_DIR/root_hash

rm $OUT_DIR/files_count

touch $OUT_DIR/asl_list

touch $OUT_DIR/root_hash

touch $OUT_DIR/files_count

for FILE in `find $SYSTEM_DIR -type f -o -type l | busybox sort -f`
do
echo $(sha1sum $FILE)
SUM_STRING="$SUM_STRING\n$(sha1sum $FILE)"
done

echo -e $SUM_STRING | sed '1d' > $OUT_DIR/asl_list

echo '"'$(sha1sum $OUT_DIR/asl_list | cut -b 1-40)'"' > $OUT_DIR/root_hash

echo "ROOT HASH OF THE SYSTEM IS : "$(sha1sum $OUT_DIR/asl_list)

CALC_COUNT_FILES=$(find $SYSTEM_DIR -type f | wc -l)

CALC_COUNT_SYMLINKS=$(find $SYSTEM_DIR -type l | wc -l)

CALC_COUNT=$(($CALC_COUNT_FILES+$CALC_COUNT_SYMLINKS))

echo "COUNT OF THE SYSTEM FILES IS : "$CALC_COUNT

echo '"'$CALC_COUNT'"' > $OUT_DIR/files_count

rm $KERNEL_OUT/security/asl/*.o

rm $KERNEL_OUT/arch/arm/boot/zImage

rm $OUT_DIR/kernel

rm $KERNEL_DIR/security/asl/root_hash

rm $KERNEL_DIR/security/asl/files_count

cp $OUT_DIR/root_hash $KERNEL_DIR/security/asl/root_hash

cp $OUT_DIR/files_count $KERNEL_DIR/security/asl/files_count


