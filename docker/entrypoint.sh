#!/bin/sh

isArgPassed() {
  arg="$1"
  argWithEqualSign="$1="
  shift
  while [ $# -gt 0 ]; do
    passedArg="$1"
    shift
    case $passedArg in
    $arg)
      return 0
      ;;
    $argWithEqualSign*)
      return 0
      ;;
    esac
  done
  return 1
}

case "$1" in

  'master')
  	ARGS="-mdir=/data -volumePreallocate -volumeSizeLimitMB=1024"
  	exec /usr/bin/weed $@ $ARGS
	;;

  'volume')
  	ARGS="-dir=/data -max=0"
  	if isArgPassed "-max" "$@"; then
  	  ARGS="-dir=/data"
  	fi
  	exec /usr/bin/weed $@ $ARGS
	;;

  'server')
  	ARGS="-dir=/data -volume.max=0 -master.volumePreallocate -master.volumeSizeLimitMB=1024"
  	if isArgPassed "-volume.max" "$@"; then
  	  ARGS="-dir=/data -master.volumePreallocate -master.volumeSizeLimitMB=1024"
  	fi
  	exec /usr/bin/weed $@ $ARGS
  	;;

  'filer')
  	ARGS=""
  	exec /usr/bin/weed $@ $ARGS
	;;

  's3')
  	ARGS="-domainName=$S3_DOMAIN_NAME -key.file=$S3_KEY_FILE -cert.file=$S3_CERT_FILE"
  	exec /usr/bin/weed $@ $ARGS
	;;

  'cronjob')
	MASTER=${WEED_MASTER-localhost:9333}
	FIX_REPLICATION_CRON_SCHEDULE=${CRON_SCHEDULE-*/7 * * * * *}
	echo "$FIX_REPLICATION_CRON_SCHEDULE" 'echo "volume.fix.replication" | weed shell -master='$MASTER > /crontab
	BALANCING_CRON_SCHEDULE=${CRON_SCHEDULE-25 * * * * *}
	echo "$BALANCING_CRON_SCHEDULE" 'echo "volume.balance -c ALL -force" | weed shell -master='$MASTER >> /crontab
	echo "Running Crontab:"
	cat /crontab
	exec supercronic /crontab
	;;
  *)
  	exec /usr/bin/weed $@
	;;
esac
