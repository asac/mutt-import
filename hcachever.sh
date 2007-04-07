#!/bin/sh

BASEVERSION=1

if test -x "`which md5`"
then
  MD5=md5
elif test -x "`which md5sum`"
then
  MD5=md5sum
elif test -x "`which openssl`"
then
  MD5="openssl md5 -hex"
else
  echo "ERROR: no MD5 tool found"
  exit 1
fi

cleanstruct () {
  echo "$1" | sed -e 's/} *//' -e 's/;$//'
}

cleanbody () {
  echo "$1" | sed -e 's/{ *//'
}

getstruct () {
  STRUCT=""
  BODY=''
  inbody=0
  case "$1" in
    *'{') inbody=1 ;;
    *';') return ;;
  esac

  while read line
  do
    if test $inbody -eq 0
    then
      case "$line" in
        '{'*) inbody=1 ;;
        *';') return ;;
      esac
    fi

    case "$line" in
      '} '*)
        STRUCT=`cleanstruct "$line"`
        break
      ;;
      '}')
        read line
        STRUCT=`cleanstruct "$line"`
        break
      ;;
      '#'*) continue ;;
      *)
        if test $inbody -ne 0
        then
          BODY="$BODY $line"
        fi
      ;;
    esac
  done

  case $STRUCT in
    ADDRESS|LIST|BUFFER|PARAMETER|BODY|ENVELOPE)
      BODY=`cleanbody "$BODY"`
      echo "$STRUCT: $BODY"
    ;;
  esac
  return
}

DEST="$1"
TMPD="$DEST.tmp"

TEXT="$BASEVERSION"

echo "/* base version: $BASEVERSION" > $TMPD
while read line
do
  case "$line" in
    'typedef struct'*)
       STRUCT=`getstruct "$line"`
       if test -n "$STRUCT"
       then
	 NAME=`echo $STRUCT | cut -d: -f1`
	 BODY=`echo $STRUCT | cut -d' ' -f2-`
         echo " * $NAME:" $BODY >> $TMPD
         TEXT="$TEXT $NAME {$BODY}"
       fi
    ;;
  esac
done
echo " */" >> $TMPD

MD5TEXT=`echo "$TEXT" | $MD5`
echo "#define HCACHEVER 0x"`echo $MD5TEXT | cut -c-8` >> $TMPD

# TODO: validate we have all structs

mv $TMPD $DEST
