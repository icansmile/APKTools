#!/bin/sh

echo "----------------start build.sh------------------"

out="./apk/output.apk"

#母包路径
originAPK="./apk/demo.apk"

#SDK AndroidManifest.xml路径
sdkAndroidManifest="./apk/AndroidManifest.xml"

#SDK assets路径
sdkAssets="./apk/assets"

#SDK jar包路径
sdkLibs="./apk/libs"

#SDK dex路径
sdkDex="./temps/sdkDex"

#SDK smali路径
sdkSmali="./temps/sdkSmali"

#反编译工程路径
unpackAPK="./temps/unpackAPK"

#重编译APK路径
apkUnsigned="./apk/apkUnsigned.apk"

#重签名APK路径
apkSigned="./apk/apkSigned.apk"

#重签名且优化后APK路径
apkAligned="./apk/apkAligned.apk"

#apktool路径
apktool="./tool/apktool/apktool"
jar2dex="./tool/dex2jar-2.0/d2j-jar2dex.sh"
baksmali="./tool/baksmali-2.1.2.jar"
zipalign="./tool/zipalign"
aapt="./tool/aapt"
adb="./tool/adb"

# ------------------------密钥---------------------------

# 密钥路径
keystore="./config/keystore/demo.keystore"

# 密钥别名
keyAlias="demo"

# 密钥库口令
storePass="keystore"

# 私有密钥口令
keyPass="keystore"




function unpackAPK()
{
	echo "\nEnter APK Path\n"
	
	#母包路径
	read originAPK

	echo "\n----------------start unpack $1------------------"

	echo "first clean ${unpackAPK}"
	rm -rf "${unpackAPK}/*"

	# 反编译apk母包
	"$apktool" d -f "$originAPK" -o "$unpackAPK"

	open $unpackAPK

	return 0
}

function readApkInfo()
{
	echo "\nEnter APK Path"
	read originAPK

	$aapt dump badging $originAPK

	return 0
}

function installAPKOnSimulator()
{
	echo "\nEnter APK Path"
	read originAPK

	$adb install originAPK

	return 0
}

function packAPK()
{
	# 重新打包APK
	"$apktool" b -f "$unpackAPK" -o "$apkUnsigned"

	# 重新签名
	jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore "$keystore" -storepass "$storePass" -keypass "$keyPass" -signedjar "$apkSigned" "$apkUnsigned" "$keyAlias" 

	# zipalign优化APK包
	"$zipalign" -f -v 4 "$apkSigned" "$apkAligned"

	rm -rf "${apkUnsigned}"
	rm -rf "${apkSigned}"

	# 移动，重命名
	mv -vf "$apkAligned" "$out"
}

function repackAPK()
{
	echo "\nEnter APK Path"
	read originAPK

	echo "\nEnter Option"
	echo "need to add or replace : 1.libs 2.assets 3.AndroidManifest.xml"
	echo "example: just add libs, then enter 100 (true,false,false)"
	read option

	add_libs=0
	add_assets=0
	add_Androidmanifest=0

	add_libs=`expr $option / 100`
	add_assets=`expr $option / 10`
	add_Androidmanifest=`expr $option % 100`

	echo "$add_libs + $add_assets + $add_Androidmanifest"

	echo "\n----------------target begin $1------------------"

	echo "clean ${sdkDex}"
	rm -rf "${sdkDex}/*"

	echo "clean ${sdkSmali}"
	rm -rf "${sdkSmali}/*"

	echo "clean ${unpackAPK}"
	rm -rf "${unpackAPK}/*"

	# 反编译apk母包
	"$apktool" d -f "$originAPK" -o "$unpackAPK"

	# 添加libs
	if [[ $add_libs -eq 1 ]]; then	
		for filename in `ls $sdkLibs`
		do
			f_name=$(basename $filename .jar)
			f_jar="${sdkLibs}/${f_name}.jar"
			f_dex="${sdkDex}/${f_name}.dex"

			# SDK jar包 转 dex
			"$jar2dex" -f "$f_jar" -o "$f_dex"
			# dex 转 Smali
			java -jar "$baksmali" "$f_dex" -o "$sdkSmali"
		done

		# 替换Smali
		cp -prv "$sdkSmali/" "$unpackAPK/smali"
	fi

	# 添加assets
	if [[ $add_assets -eq 1 ]]; then	
		cp -prv "$sdkAssets/" "$unpackAPK/assets"
	fi
	
	#替换AndroidManifest.xml
	if [[ $add_Androidmanifest -eq 1 ]]; then
		cp -prv "$sdkAndroidManifest" "$unpackAPK/AndroidManifest.xml"
	fi

	# 重新打包APK
	"$apktool" b -f "$unpackAPK" -o "$apkUnsigned"

	# 重新签名
	jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore "$keystore" -storepass "$storePass" -keypass "$keyPass" -signedjar "$apkSigned" "$apkUnsigned" "$keyAlias" 

	# zipalign优化APK包
	"$zipalign" -f -v 4 "$apkSigned" "$apkAligned"

	rm -rf "${apkUnsigned}"
	rm -rf "${apkSigned}"

	# 移动，重命名
	mv -vf "$apkAligned" "$out"
}



echo "1.unpackAPK	2.readApkInfo	3.installAPKOnSimulator		4.repackAPK		5.packAPK"
echo "Enter Option"
read option

if [[ option -eq 1 ]]; then
	unpackAPK
elif [[ option -eq 2 ]]; then
	readApkInfo	
elif [[ option -eq 3 ]]; then
	installAPKOnSimulator
elif [[ option -eq 4 ]]; then
	repackAPK
elif [[ option -eq 5 ]]; then
	packAPK
fi



exit
