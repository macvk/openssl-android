#!/bin/sh

# 1. change the `f` and `n` accordingly
# 2. run script

f=3.0.0-alpha13
n=android-ndk-r20b
#n=android-ndk-r21e

ff=openssl-$f.tar.gz
nn=$n-linux-x86_64

SCRIPTPATH=`pwd`

if [ ! -d "$SCRIPTPATH/$n" ] ; then
	wget https://dl.google.com/android/repository/$nn.zip
	unzip $nn.zip
	rm -f $nn.zip
fi

if [ ! -d "$SCRIPTPATH/openssl-$f" ] ; then
	wget --no-check-certificate https://www.openssl.org/source/$ff -O $ff
	tar -xvzf $ff -C .
	rm -f $ff
fi

export ANDROID_NDK_ROOT=$SCRIPTPATH/$n
p=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin

cd openssl-$f

for r in x86 x86_64 arm64 arm; do

	PATH=$p:$PATH
	make clean

	if [ $r == "x86" ] ; then
		./Configure -latomic --release --prefix=$SCRIPTPATH/android-openssl-$f/$r --openssldir=$SCRIPTPATH/android-openssl-$f/$r no-tests android-$r -D__ANDROID_API__=21
	elif [ $r == "arm" ] ; then
		./Configure --release --prefix=$SCRIPTPATH/android-openssl-$f/$r --openssldir=$SCRIPTPATH/android-openssl-$f/$r no-tests android-$r -D__ANDROID_API__=21
        else
		./Configure --release --prefix=$SCRIPTPATH/android-openssl-$f/$r --openssldir=$SCRIPTPATH/android-openssl-$f/$r no-tests android-$r -D__ANDROID_API__=21
	fi

#       ./Configure -latomic --release --prefix=$SCRIPTPATH/android-openssl-$f/$r --openssldir=$SCRIPTPATH/android-openssl-$f/$r no-dso no-stdio no-tests android-$r -D__ANDROID_API__=$API
#       ./Configure -latomic --release --prefix=$SCRIPTPATH/android-openssl-$f/$r --openssldir=$SCRIPTPATH/android-openssl-$f/$r no-tests android-$r -D__ANDROID_API__=$API

	res=$?
	if [ ! $res -eq 0 ]; then
		echo "config has returned '$res' stop"
		exit
	fi

	sed -ie '/libcrypto.so:/,+2d' Makefile
	sed -ie '/libssl.so:/,+2d' Makefile
	sed -ie 's/.so.3/.so/g' Makefile
	sed -ie '/ln -sf $$fn1/,+1d' Makefile

	make
	res=$?
	if [ ! $res -eq 0 ]; then
		echo "make has returned '$res' stop"
		exit
	fi
	make install_sw

done
