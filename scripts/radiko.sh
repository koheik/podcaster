#!/bin/sh

RTMPDUMP=/home/koheik/root/bin/rtmpdump
FFMPEG=/home/koheik/root/bin/ffmpeg
OUTFILEBASEPATH=/home/koheik/www/podcast/files

FLVFILEEXT=".flv"
AACFILEEXT=".aac"
MP3FILEEXT=".mp3"

#playerurl=http://radiko.jp/player/swf/player_2.0.1.00.swf
playerurl=http://radiko.jp/player/swf/player_3.0.0.01.swf
playerfile=/home/koheik/radiko/player.swf
keyfile=/home/koheik/radiko/authkey.png
base64=/home/koheik/bin/base64.pl
wget=/usr/local/bin/wget
swfextract=/home/koheik/root/bin/swfextract

if [ $# -eq 3 ]; then
  OUTFILEPREFIX=$1
  RECTIMEMIN=$2
  CHANNEL=$3
else
  echo "usage : $0 OUTFILEPREFIX RECTIMEMIN CHANNEL"
  exit 1
fi

OUTFILEPREFIX=$1
RECTIMEMIN=$2
CHANNEL=$3

OUTFILENAME=${OUTFILEBASEPATH}/${OUTFILEPREFIX}_`date +%Y_%m_%d`

MARGINTIMEMIN=1
RECTIME=`expr ${RECTIMEMIN} \* 60 + ${MARGINTIMEMIN} \* 2 \* 60`

cd ${OUTFILEBASEPATH}

#
# get player
#
if [ ! -f $playerfile ]; then
  ${wget} -q -O $playerfile $playerurl

  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

#
# get keydata (need swftools)
#
if [ ! -f $keyfile ]; then
#  ${swfextract} -b 5 $playerfile -o $keyfile
  ${swfextract} -b 14 $playerfile -o $keyfile

  if [ ! -f $keyfile ]; then
    echo "failed get keydata"
    exit 1
  fi
fi

if [ -f auth1_fms_${OUTFILEPREFIX}_${CHANNEL} ]; then
  rm -f auth1_fms_${OUTFILEPREFIX}_${CHANNEL}
fi

#
# access auth1_fms
#
${wget} -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --post-data='\r\n' \
     --no-check-certificate \
     --save-headers \
     --tries=5 \
     --timeout=5 \
     -O auth1_fms_${OUTFILEPREFIX}_${CHANNEL} \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  exit 1
fi

#
# get partial key
#
authtoken=`cat auth1_fms_${OUTFILEPREFIX}_${CHANNEL} | perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)'`
offset=`cat auth1_fms_${OUTFILEPREFIX}_${CHANNEL} | perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)'`
length=`cat auth1_fms_${OUTFILEPREFIX}_${CHANNEL} | perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)'`

partialkey=`dd if=${keyfile} bs=1 skip=${offset} count=${length} | ${base64}`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f auth1_fms_${OUTFILEPREFIX}_${CHANNEL}

if [ -f auth2_fms_${OUTFILEPREFIX}_${CHANNEL} ]; then
  rm -f auth2_fms_${OUTFILEPREFIX}_${CHANNEL}
fi

#
# access auth2_fms
#
${wget} -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-Authtoken: ${authtoken}" \
     --header="X-Radiko-Partialkey: ${partialkey}" \
     --post-data='\r\n' \
     --no-check-certificate \
     --tries=5 \
     --timeout=5 \
     -O auth2_fms_${OUTFILEPREFIX}_${CHANNEL} \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f auth2_fms_${OUTFILEPREFIX}_${CHANNEL} ]; then
  echo "failed auth2 process"
  exit 1
fi

echo "authentication success"

areaid=`cat auth2_fms_${OUTFILEPREFIX}_${CHANNEL} | perl -ne 'print $1 if(/^([^,]+),/i)'`
echo "areaid: $areaid"

rm -f auth2_fms_${OUTFILEPREFIX}_${CHANNEL}

#
# rtmpdump
#
RETRYCOUNT=0
while :
do
#  ${RTMPDUMP} -v \
#              -r "rtmpe://radiko.smartstream.ne.jp" \
#              --playpath "simul-stream" \
#              --app "${CHANNEL}/_defInst_" \
#  ${RTMPDUMP} -v \
#              -r "rtmpe://w-radiko.smartstream.ne.jp" \
#              --playpath "simul-stream.stream" \
#              --app "${CHANNEL}/_definst_" \
#              -W $playerurl \
#              -C S:"" -C S:"" -C S:"" -C S:$authtoken \
#              --live \
#              --flv ${OUTFILENAME}${FLVFILEEXT} \
#              --stop ${RECTIME}
  ${RTMPDUMP} -v \
              -r "rtmpe://f-radiko.smartstream.ne.jp" \
              --playpath "simul-stream.stream" \
              --app "${CHANNEL}/_definst_" \
              -W $playerurl \
              -C S:"" -C S:"" -C S:"" -C S:$authtoken \
              --live \
              --flv ${OUTFILENAME}${FLVFILEEXT} \
              --stop ${RECTIME}
  if [ $? -ne 1 -o `wc -c ${OUTFILENAME}${FLVFILEEXT} | awk '{print $1}'` -ge 10240 ]; then
    break
  elif [ ${RETRYCOUNT} -ge 5 ]; then
    echo "failed rtmpdump"
    exit 1
  else
    RETRYCOUNT=`expr ${RETRYCOUNT} + 1`
  fi
done

# ${FFMPEG} -y -i "${OUTFILENAME}${FLVFILEEXT}" -vn -acodec copy "${OUTFILENAME}${AACFILEEXT}"
# rm -f ${OUTFILENAME}${FLVFILEEXT}
${FFMPEG} -y -i "${OUTFILENAME}${FLVFILEEXT}" -vn -b:a 64k -write_xing 0 "${OUTFILENAME}${MP3FILEEXT}"
