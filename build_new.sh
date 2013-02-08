#!/bin/sh

buildOneChannel()
{

#if [ $# -lt 1 ];then
#    echo "      The argument count is less then 1, Please input the correct argument ......"
#    exit 0
#fi

#echo ">>>>>> replace the [[channel]]  to [[$1]] first >>>>>"

#cat AndroidManifest.xml | sed 's/meta-data.*android:name=\"YOUMI_CHANNEL\".*android:value=\".*\"/meta-data android:name=\"YOUMI_CHANNEL\" android:value=\"'$1'\"/' > AndroidManifest.xml_tmp

#mv AndroidManifest.xml_tmp AndroidManifest.xml

#echo "<<<<<<< after replace the [[channel]] >>>>>>>>>"
#echo "[[channel]] check the channel for [[$1]] ......"
#PARAM_CHANNEL=$1
#REAL_CHANNEL=`grep 'android:name="YOUMI_CHANNEL"' AndroidManifest.xml | sed 's/.*value=\"'$1'\".*/'$1'/'`

#if [ "$PARAM_CHANNEL" = "$REAL_CHANNEL" ];then
#	echo ">>>>>>>>> check the channel replace success >>>>>>>"
#else
#	echo ">>>>>>>>> check the channel replace failed >>>>>>>"
#	exit 0
#fi
#sleep 1

demo_version=`grep "android:versionName=" AndroidManifest.xml | sed 's/.*=//' | sed 's/"//' | awk 'BEGIN{FS="\""}{print $1}'`
echo "********* begin build for $demo_version *********"
ant clean ; ant release
echo ""
echo ""
echo ""
echo ""
echo ">>>>>>> after build for Book-release.apk >>>>>>>"
sleep 1

echo cp -rf bin/Book-release.apk $1/Book_$demo_version.apk
cp -rf bin/Book-release.apk $1/Book_$demo_version.apk

}

replace_info()
{
app_name=$1
package_name=$2
app_id=$3
app_secrect=$4
vcode=$5
vname=$6

########### app name ##############
echo ">>>>>> replace app name to [[$app_name]] >>>>>>"
APP_NAME_FILE=res/values/strings.xml
APP_NAME_FILE_TMP=res/values/strings.xml_tmp
sed 's/app_name.*>/app_name">'$app_name'<\/string>/' $APP_NAME_FILE > $APP_NAME_FILE_TMP
mv $APP_NAME_FILE_TMP $APP_NAME_FILE
echo "current app name : [[`grep "app_name" $APP_NAME_FILE`]]"
echo ""
echo ""
echo ""
sleep 1

############ key ################
echo ">>>>>> replace key to app_id : [[$app_id]] and app secrect : [[$app_secrect]] >>>>>>"
echo "<<<<<<<< [[repalce key first]] >>>>>>>"
replace_file=src/org/geometerplus/android/fbreader/Config.java
replace_file_tmp=src/org/geometerplus/android/fbreader/Config.java_tmp
sed 's/APP_ID.*;/APP_ID = "'$app_id'";/' $replace_file > $replace_file_tmp
mv $replace_file_tmp $replace_file
sed 's/APP_SECRET_KEY.*;/APP_SECRET_KEY = "'$app_secrect'";/' $replace_file > $replace_file_tmp
mv $replace_file_tmp $replace_file
cat $replace_file
echo ""
echo ""
echo ""
sleep 1

########### code and name ###########
echo ">>>>> replace version code and version name >>>>>"
sed 's/android:versionCode=\".*\"/android:versionCode="'$vcode'"/' AndroidManifest.xml | sed 's/android:versionName=\"[0-9].[0-9]\"/android:versionName="'$vname'"/' > AndroidManifest.xml_tmp
mv AndroidManifest.xml_tmp AndroidManifest.xml
echo ">>>>>> now version info in Manifest : "
grep "android:version" AndroidManifest.xml
echo ""
echo ""
echo ""
sleep 1

########### package name #############
echo ">>>>>> replace package name to [[org.geometerplus.zlibrary.ui.$package_name]] >>>>>>"
work_folder=src
replace_from_package=`grep "package=" AndroidManifest.xml | sed 's/.*org.geometerplus.zlibrary.ui.//g' | sed 's/\"//'`
replace_from=org.geometerplus.zlibrary.ui.$replace_from_package
replace_to=org.geometerplus.zlibrary.ui.$package_name
echo "[[replace_from]] package data from $replace_from >>>> to $replace_to"

for text_file in `find $work_folder -type f|xargs grep -l $replace_from`
do echo "Editing file $text_file, replace $replace_from with $replace_to"
sed -e "s/$replace_from/$replace_to/g" $text_file > /tmp/fbreplace        
mv -f /tmp/fbreplace $text_file
done  

echo ">>>>> replace done >>>>>>>"
sleep 1

sed -e "s/$replace_from/$replace_to/g" AndroidManifest.xml > /tmp/fbreplace        
mv -f /tmp/fbreplace AndroidManifest.xml
sleep 2

res_dir=res
for res_file in `find $res_dir -type f|xargs grep -l $replace_from`
do echo "Editing file $res_file, replace $replace_from with $replace_to"
sed -e "s/$replace_from/$replace_to/g" $res_file > /tmp/fbreplace        
mv -f /tmp/fbreplace $res_file
done
sleep 1
echo ">>>>> begin mv the src dir >>>>>>"
cd src/org/geometerplus/zlibrary/ui

if [ ! -d $package_name ];then
    ls
    echo mv $replace_from_package $package_name
    mv $replace_from_package $package_name
fi

echo "now pakcage name : `ls`"
echo ""
echo ""
echo ""
cd -
############### end package name ###########
}

updateVersion()
{
CONFIG_FILE=$1/config.txt
versionCode=`grep "version_code" $CONFIG_FILE | sed 's/.*=//'`
versionName=`grep "version_name" $CONFIG_FILE | sed 's/.*=//'| sed 's/\.//'`

echo "current version info code : [[$versionCode]] and name : [[$versionName]]"
versionCode=`expr $versionCode + 1`
versionName=`expr $versionName + 1`
versionName=${versionName:0:${#versionName} - 1}.${versionName:${#versionName} - 1}
echo "after update, code : [[$versionCode]] and name : [[$versionName]]"
sleep 1
sed 's/android:versionCode=\".*\"/android:versionCode="'$versionCode'"/' AndroidManifest.xml | sed 's/android:versionName=\"[0-9].[0-9]\"/android:versionName="'$versionName'"/' > AndroidManifest.xml_tmp
mv AndroidManifest.xml_tmp AndroidManifest.xml
echo ">>>>>> now version info in Manifest : "
grep "android:version" AndroidManifest.xml

echo "update version info in $CONFIG_FILE"
CONFIG_TMP=$CONFIG_FILE-tmp
sed 's/version_code=.*/version_code='$versionCode'/' $CONFIG_FILE | sed 's/version_name=.*/version_name='$versionName'/' > $CONFIG_TMP
mv $CONFIG_TMP $CONFIG_FILE
cat $CONFIG_FILE
echo ""
echo ""
echo ""
sleep 1
}

if [ ! -d $1 ];then
	echo "!!!!!! target dir : $1 is not exist, please check the dir first ...... !!!!!!!"
	exit 0
fi

if [ ! -e "$1/config.txt" ];then
	echo "!!!!!! config file : $1/config.txt is not exits, please check first ..... !!!!!!"
	exit 0
fi

if [ ! -e "$1/icon.png" ];then
	echo "!!!!!! $1/icon.png not exist, just exit ...... !!!!!"
	exit 0
fi

if [ ! -e "$1/book.epub" ];then
	echo "!!!!! $1/book.epub not exist, just exit ...... !!!!!"
	exit 0
fi

cp -rf $1/icon.png res/drawable/icon.png
cp -rf $1/book.epub assets/book/book.epub

APP_NAME=`grep "app_name" $1/config.txt | sed 's/.*=//'`
PACKAGE_NAME=`grep "package" $1/config.txt | sed 's/.*org.geometerplus.zlibrary.ui.//g'`
APP_ID=`grep "app_id" $1/config.txt | sed 's/.*=//'`
APP_SECRET=`grep "app_secrect" $1/config.txt | sed 's/.*=//'`
VERSION_CODE=`grep "version_code" $1/config.txt | sed 's/.*=//'`
VERSION_NAME=`grep "version_name" $1/config.txt | sed 's/.*=//'`
replace_info $APP_NAME $PACKAGE_NAME $APP_ID $APP_SECRET $VERSION_CODE $VERSION_NAME

if [ $# == 2 ];then
	if [ "$2" == "update" ];then
		updateVersion $1
	fi
fi

echo "clean old apk ......"
echo rm -rf $1/*.apk
rm -rf $1/*.apk

buildOneChannel $1
echo 
echo 
echo 
echo 
echo "reset code to HEAD >>>>>>>>>>"
echo 
echo 
echo 
git add .
git reset --hard HEAD
git log --pretty=short
