#!/bin/bash

for (( i=0; i<$1; i++ )); do
    echo $i
    ./REPRO
    RETCODE=$?
    if (( $RETCODE != 0 )); then
        echo "FAILED"
        exit $RETCODE
    else
        echo "passed"
    fi
done
