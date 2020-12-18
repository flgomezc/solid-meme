#!/bin/sh

stat_test () {
    echo "testing gfal-stat $1" 
    gfal-stat $1
    EXITCODE_s=$?
}

copy_test () {
    gfal-copy $1 /tmp/
    EXITCODE_c=$?
}

sum_test () {
    BASENAME='/tmp/'`basename "$1"`
    echo "testing gfal-sum $BASENAME adler32" 
    string=`gfal-sum $BASENAME adler32`
    stringarray=($string)
    CHECKSUM=${stringarray[1]}
    EXITCODE_a=$?
    return $EXITCODE
}

expected_checksum (){
    local filename="cms:"$1
    echo "looking for ADLER43 with rucio list-file-replicas $filename"
    local TEXT=`rucio list-file-replicas $filename`
    local mult=($TEXT)
    ADLER32="${mult[22]}"
    #return ADLER32
}



eval_file (){

    local PREFIX=$1
    local FILENAME=$2
    
    PFN=$PREFIX$FILENAME
    stat_test $PFN
    
    corrupted=1

    if [[ $EXITCODE_s == 0 ]] ; then
	echo "gfal-stats OK, proceed...";

	copy_test $PFN
	if [[ $EXITCODE_c == 0 ]]; then
	    echo "gfal-copy OK, proceed...";
	    
	    sum_test $PFN
	    if test $EXITCODE_a -eq 0 ; then
		echo "gfal-sum OK, proceed.";
		echo "          SUM = $CHECKSUM";

		expected_checksum $FILENAME
		echo " Expected SUM = $ADLER32";
		if [[ "$CHECKSUM" == "$ADLER32" ]]; then
		    echo "FILE IS OK";
		    corrupted=0
		fi
	    fi
	fi
    fi
    
    if [[ $corrupted = 1 ]]; then
	echo "File has errors, INVALIDATE.";
	echo $PFN >> list.dat    
    fi
}
 


touch list.dat
#eval_file $PREFIX $FILENAME;

while read line; do
    PREFIX='srm://dcache-se-cms.desy.de:8443/srm/managerv2?SFN=/pnfs/desy.de/cms/tier2'
    FILENAME="$line"
    echo " "
    echo "Testing $FILENAME"
    eval_file $PREFIX $FILENAME;
done <desy_missing_clean.dat
#done <miniset.dat
