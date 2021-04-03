# PTtool

# 硬链接工具

## mklink.sh
修改脚本参数源目录，目的目录,替换为你自己的目录。
脚本将把源目录所有文件硬链接到目的目录，小于1M的文件直接复制到目的目录。方便nfo等小文件刮削修改
```
SRC="/share/Download/tmp/src"
DST="/share/Download/tmp/dst"
```

## dirlink.sh
可以直接修改脚本参数，可以从参数$!,$2输入源目录，目的目录。
此脚本和mklink.sh区别在于，将检查每个目录是否已经被硬链接过，已经连接过的将跳过去不再硬链接。
原理是在源文件夹目录下添加文件islinked.lk，通过检测这个文件来判断是否硬链接过
```
SRC="/share/Download/tmp/src"
DST="/share/Download/tmp/dst"
```
