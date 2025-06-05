#!/data/data/com.termux/files/usr/bin/bash

# Setup directories
PROJECT_DIR=$(pwd)/app
SRC_DIR=$PROJECT_DIR/src/main
RES_DIR=$SRC_DIR/res
ASSETS_DIR=$SRC_DIR/assets
JAVA_DIR=$SRC_DIR/java
BUILD_DIR=$PROJECT_DIR/build
CLASSES_DIR=$BUILD_DIR/classes
R_DIR=$BUILD_DIR/R
APK_DIR=$BUILD_DIR/apk
ANDROID_JAR=/data/data/com.termux/files/usr/lib/android-sdk/platforms/android-33/android.jar

# Create build directories
mkdir -p $CLASSES_DIR $R_DIR $APK_DIR

# Compile resources with aapt
aapt package -f -m -J $R_DIR -M $SRC_DIR/AndroidManifest.xml \
    -S $RES_DIR -A $ASSETS_DIR -I $ANDROID_JAR

# Compile Java code
ecj -d $CLASSES_DIR -sourcepath $JAVA_DIR -classpath $ANDROID_JAR $R_DIR/com/example/numberwin/R.java $JAVA_DIR/com/example/numberwin/MainActivity.java

# Convert to DEX
dx --dex --output=$CLASSES_DIR/classes.dex $CLASSES_DIR

# Package resources into APK
aapt package -f -M $SRC_DIR/AndroidManifest.xml -S $RES_DIR -A $ASSETS_DIR \
    -I $ANDROID_JAR -F $APK_DIR/unaligned.apk

# Add DEX to APK
cd $CLASSES_DIR
zip -u $APK_DIR/unaligned.apk classes.dex

# Align APK
zipalign -f 4 $APK_DIR/unaligned.apk $APK_DIR/aligned.apk

# Sign APK
if [ ! -f ~/.keystore ]; then
    keytool -genkey -v -keystore ~/.keystore -alias numberwin -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=NumberWin, OU=Dev, O=NumberWin, L=Unknown, S=Unknown, C=US"
fi
apksigner sign --ks ~/.keystore --ks-key-alias numberwin --ks-pass pass:android $APK_DIR/aligned.apk

# Move final APK to Downloads
cp $APK_DIR/aligned.apk /sdcard/Download/NumberWin.apk

echo "APK built and copied to /sdcard/Download/NumberWin.apk"
