#!/sbin/sh

ENABLED=$(cat /proc/asl/enabled)

sha1check() 
{
touch /dev/asl/asl_protocol

echo "$(sha1sum -c '/dev/asl/asl_list')" > /dev/asl/asl_protocol
}

proto_parse()
{
touch /dev/asl/detected

cat /dev/asl/asl_protocol | grep "FAILED" > /dev/asl/detected
}

recovery_mode()
{
reboot recovery
}

check_status()
{
cat /dev/asl/detected | 
(while read line
do
if [ -n "$line" ]
 then
  echo '0' > /proc/asl/status
  recovery_mode
 else
  echo '1' > /proc/asl/status
fi
done
)
}

if [ "$ENABLED" == "1" ]
 then

       cp /proc/asl/list /dev/asl/asl_list
       
       sha1check

       proto_parse

       check_status

 else
   echo '0' > /proc/asl/status
fi
