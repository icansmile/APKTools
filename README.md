# APKTools
Some apk tools.  unpackAPK, readApkInfo, installAPKOnSimulator, repackAPK, packAPK
## How to use
excute util.sh
```
cd APKTools
util.sh
```
### Functions
1. unpackAPK
after it, you can find resources in temps/unpackAPK
2. readAPKInfo
3. installAPKOnSimulator
useless
4. repackAPK
first unpack the apk
put resources in apk/assets
put jar in libs
then replace them
last repack apk
you can find the new apk in apk/output.apk
5. packAPK
pack resources from temp/unpackAPK
