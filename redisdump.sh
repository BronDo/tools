#!/bin/sh

host=127.0.0.1
port=6379
passwd=qweqwe
dbid=1
dir=redis.dump.d

while test $# -gt 0; do
    case "$1" in
        --help)
            echo $"Usage: \`$0 [OPTION]... {dump|restore}
                --help      print this help and exit
            -h, --host      Server hostname (default: 127.0.0.1).
            -p, --port      Server port (default: 6379).
            -a, --passwd    Password to use when connecting to the server.
            -n, --db        Database Number (default: 1).
            -d, --dir       Dump/Read data To/From dir."
            exit 0
            ;;
        -h | --host)
            host=$2
            shift; shift
            ;;
        -p | --port)
            port=$2
            shift; shift
            ;;
        -a | --passwd)
            passwd=$2
            shift; shift
            ;;
        -n | --db)
            dbid=$2
            shift; shift
            ;;
        -d | --dir)
            dir=$2
            shift; shift
            ;;
        --)
            shift; break
            ;;
        -*)
            echo >&2 'redisdump:' $"unrecognized option" "\`$1'"
            echo >&2 $"Try \`redisdump --help' for more information."
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

alias dbDo="redis-cli -h $host -p $port -a $passwd -n $dbid"

function dump() {
for key in `dbDo keys "*"`; do
    dbDo --raw dump $key | head -c-1 > ${dir}/${key}
done
echo $"dump data to directory $dir"
}

function restore() {
read -r -p "Restore Need Flushdb, Are You Sure? [Y/n]" input

case $input in
    [yY][eE][sS]|[yY])
        dbDo flushdb
        ;;
    [nN][oO]|[nN])
        exit 1
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

for file in `ls $dir`; do
    cat ${dir}/${file} | dbDo -x restore `basename ${file}` 0
done
}

case "$1" in
    dump)
        if [ -f $dir ]; then
            echo >&2 'redisdump:' $"can't mk dir"
            exit 2
        fi
        if [ ! -d $dir ]; then
            mkdir $dir
        fi
        dump
        ;;
    restore)
        if [ ! -d $dir ]; then
            echo >&2 'redisdump:' $"\`$dir not dir"
            exit 2
        fi
        restore
        ;;
    *)
        echo $"Usage: $0 {dump|restore}"
        ;;
esac

exit 0
