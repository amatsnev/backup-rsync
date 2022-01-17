#!/bin/bash

##. /home/vlad/scripts/func.inc

. /home/vlad/scripts/backup/backup.cfg


# get yq with $param1
getyqv() {
  yq e $1 $BASES
}

#get yq with name .bases[].name
get_yq_v_byname() {
  t=".bases[]|select(.name==\"$1\")|.$2"
  q=$(getyqv $t)
  if [[ $q == "null" ]] ; then q='' ;fi
  echo $q
}

rsyncbackup() {

# определяем для некоторых свой каталог бекапа
# if [ -f $CONFIG_DIR/$1 ]; 
#    then 
#    BACKUP1=`cat $CONFIG_DIR/$1`
#    else
#    BACKUP1=$BACKUP
# fi
 BACKUP1=$BACKUP

 echo `date` $1 into dir $BACKUP1>>$LOGDIR/b-$1.log
 #echo `date` $BACKUP1 $LOGDIR/b-$1.log

 # mkdir if not exist 
 [ ! -d $BACKUP1/$YEAR/$MONTH/$1 ] && mkdir -p $BACKUP1/$YEAR/$MONTH/$1
 echo `date` ---------------------------------------- >>$LOGDIR/b-$1.log
 #echo `date` starting backup from $1 >>$LOGDIR/b-$1.log
 
 ### check if process exist
 GetPID=$(<$PID/$1)
 #if  kill -0 $GetPID; then echo "Уже запущено" ; fi
 if [ -n "$GetPID" -a -e /proc/$GetPID ]; then echo  `date` "Уже запущено">>$LOGDIR/b-$1.log ;  else rm -f $PID/$1; fi 
 ## else exit
 [ -f $PID/$1 ] && return || echo $BASHPID>$PID/$1

 # start backup with rsync
 ping -c 3 $2 | grep "packet" >>$LOGDIR/b-$1.log 2>&1 
 rsync -a --compress=9 --timeout=120  rsync://$2/backup/*  $BACKUP1/$YEAR/$MONTH/$1 >>$LOGDIR/b-$1.log 2>&1
 if (($? ==0)); then
#    mv $TMP_BACKUP/* $BACKUP1
    # if complete 
    rsync  -vrd --delete  $TMP_BACKUP/ rsync://$2/backup 
    echo `date` backup from $1 COMPLETE >>$LOGDIR/b-$1.log
    
    fi
    return 0
}


# STARTING HERE
# fork every params 
for param in $@ ; 
do
 echo starting $param
 for i in $(getyqv '.bases[].name' ) ; do 
   name=$(get_yq_v_byname $i "name")
   if [[ "$name" == "$param" ]]; then
        ip=$(get_yq_v_byname $i "ip")
	description=$(get_yq_v_byname $i "description")
        backupdir=$(get_yq_v_byname $i "backupdir")
	# fork here VVVVVVVVVVVVVVVVVVVVVV
	rsyncbackup $name $ip $backupdir &
    fi
 done
done
