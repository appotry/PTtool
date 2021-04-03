# PTtool

# 硬链接工具
## 设计目的
方便PT用户硬链接文件，不需要再最大可能情况下节约空间，并保持做种。
小于1M的文件直接复制，方便emby，tmm等工具刮削修改nfo等小文件。
大于1M的文件硬链接到目的目录，可以修改文件名，但是不能修改文件内容！

例如：
/share/Download/src #保存下载的PT文件
/share/Download/dst #保存你自己处理过的视频文件，吧emby，tmm的目录设置到dst下面
下载脚本后chmod +x mklink.sh给与执行权限
使用mklink脚本修改如下，然后直接运行mklink.sh。就可以把src下面的文件全部硬链接到dst目录。mklink适合一次性把源文件夹链接到目的文件夹
```
SRC="/share/Download/src"
DST="/share/Download/dst"
```

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

## 修改限制2M大小以下的复制
修改脚本参数FILEGIG，原脚本是1M大小，修改为下面这样就是2M大小
```
FILEGIG=2000000c
```
## 使用声明
数据无价，小心操作。
本脚本没有rm删除，只有mkdir和cp， 最多搞乱文件系统。但要注意不要把目的地目录设置到系统目录去了。
一切后果自负

## 感觉对你有帮助，来个star吧
