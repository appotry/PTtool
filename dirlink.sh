#!/bin/sh
#auther: andycrusoe@gmail.com
#记录日志: ./dirlink.sh > dirlink.log
#使用说明: https://github.com/appotry/PTtool#readme
#同步镜像：https://gitee.com/bloodwolf/PTtool

#查找文件硬链接
#ls -ialh file.txt
#find . -inum 1234

#最后面不要加斜杠
SRC="/share/Download/tmp/src"
DST="/share/Download/tmp/dst"

FILEGIG=1000000c

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
######################################


function  mklink ()
{
    local THISSRC=$1
    local THISDST=$2
    echo "$*"
    echo "mklink:"$THISSRC $THISDST
    
    #查找大于1M的文件，硬链接
    for i in `find $THISSRC -size +$FILEGIG`
    do

        echo "work:$i"

        if [ -d $i ]; then
            echo "跳过处理目录:$i"
            echo "--"
            continue
            else if [ -e $i ]; then
            echo "THISSRC file:$i"
            fi
        fi
        
        #判断目录是否已经存在
        tmppth=`dirname $i`
        pth=${tmppth/$THISSRC/$THISDST}
        if [ ! -d $pth ]; then
            echo "mkdir -p $pth"
            mkdir -p $pth
        #else
        #    echo "跳过处理目录:$i"
        #    echo "--"
        #    continue
        fi
        
        dstfile=$pth/`basename $i`
        echo "dst file:${dstfile}"
        
        #判断文件是否已经存在
        #不存在才复制
        if [ ! -f $dstfile ]; then
          echo "cp -l $i $dstfile"
          cp -l $i $dstfile
        fi
        
        echo "--"

    done



    #查找小于1M的文件，复制小于1m的文件
    for i in `find $THISSRC -size -$FILEGIG`
    do

        echo "work:$i"

        if [ -d $i ]; then
            echo "跳过处理目录:$i"
            echo "--"
            continue
            else if [ -e $i ]; then
            echo "src file:$i"
            fi
        fi
        
        #判断目录是否已经存在
        tmppth=`dirname $i`
        pth=${tmppth/$THISSRC/$THISDST}
        if [ ! -d $pth ]; then
          echo "mkdir -p $pth"
          mkdir -p $pth
        fi
        
        dstfile=$pth/`basename $i`
        echo "dst file:${dstfile}"
        
        #判断文件是否已经存在
        #不存在才复制
        if [ ! -f $dstfile ]; then
          echo "cp $i $dstfile"
          cp $i $dstfile
        fi
        
        echo "--"

    done

    return 0
}

function servicectl_usage(){
  echo "Usage:dirlink.sh sourcedir dstdir"
  return 1 
}

function servicectl(){
[[ -z $1 || -z $2 ]] && servicectl_usage
}

if [ $# -eq 2 ]; then
    SRC=$1
    DST=$2
    echo "User set:"
    echo "src:$SRC"
    echo "dst:$DST"
else
    servicectl_usage
    echo "use default set:"
    echo "源目录src:$SRC"
    echo "目的目录dst:$DST"
fi

for dir in $(ls $SRC)
do
    echo "work dir:$dir"
    
    dstdir=$DST/$dir
    echo "当前硬链接目录"$dstdir
    
    #if [ ! -d $dstdir ]; then
        if [ ! -e $SRC/$dir/islinked.lk ]; then
            mklink "$SRC/$dir"  "$dstdir" 
            touch "$SRC/$dir"/islinked.lk
            echo "=="
        else
            echo "$dir 已经硬链接过，跳过此目录"
            echo "=="
        fi
    #fi
    
done

IFS=$SAVEIFS
