#!/bin/sh

KERNELDIR="/home/michael/android/kernels/shamu/mac_kernel_moto_shamu"
PACKAGES="/home/michael/android/kernels/shamu/package-shamu"
TOOLCHAIN="/home/michael/android/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.3-2015.03/bin"
CROSSARCH="arm"
CROSSCC="$CROSSARCH-eabi-"
USERCCDIR="/home/michael/.ccache"
DEFCONFIG="mac_defconfig"

ccache() {
	echo "[BUILD]: ccache configuration...";
	###CCACHE CONFIGURATION STARTS HERE, DO NOT MESS WITH IT!!!
	TOOLCHAIN_CCACHE="$TOOLCHAIN/../bin-ccache"
	gototoolchain() {
		echo "[BUILD]: Changing directory to $TOOLCHAIN/../ ...";
		cd $TOOLCHAIN/../
	}

	gotocctoolchain() {
		echo "[BUILD]: Changing directory to $TOOLCHAIN_CCACHE...";
		cd $TOOLCHAIN_CCACHE
	}

	#check ccache configuration
	#if not configured, do that now.
	if [ ! -d "$TOOLCHAIN_CCACHE" ]; then
		echo "[BUILD]: CCACHE: not configured! Doing it now...";
		gototoolchain
		mkdir bin-ccache
		gotocctoolchain
		ln -s $(which ccache) "$CROSSCC""gcc"
		ln -s $(which ccache) "$CROSSCC""g++"
		ln -s $(which ccache) "$CROSSCC""cpp"
		ln -s $(which ccache) "$CROSSCC""c++"
		gototoolchain
		chmod -R 777 bin-ccache
		echo "[BUILD]: CCACHE: Done...";
	fi
	export CCACHE_DIR=$USERCCDIR
	###CCACHE CONFIGURATION ENDS HERE, DO NOT MESS WITH IT!!!
}

compile() {
	echo "[BUILD]: Setting cross compile env vars...";
	export ARCH=$CROSSARCH
	export CROSS_COMPILE=$CROSSCC
	export PATH=$TOOLCHAIN_CCACHE:${PATH}:$TOOLCHAIN

	echo "[BUILD]: Cleaning kernel...";
	make clean
	rm $PACKAGES/mac_shamu*.zip
	rm $PACKAGES/kernel/zImage

	echo "[BUILD]: Using defconfig: $DEFCONFIG...";
	make $DEFCONFIG

	echo "[BUILD]: Bulding kernel...";
	make -j`grep 'processor' /proc/cpuinfo | wc -l`
	echo "[BUILD]: Done!...";
}

kernelzip() {
	if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
		echo "[BUILD]: Copy zImage to Package"
		cp arch/arm/boot/zImage-dtb $PACKAGES/kernel/zImage

		echo "[BUILD]: Make kernel.zip"
		export curdate=`date "+%m%d%Y"`
		cd $PACKAGES
		zip -r mac_shamu_$curdate.zip .
		cd $KERNELDIR
	else
		echo "[BUILD]: KERNEL DID NOT BUILD! no zImage exist"
	fi;
}

ccache && compile && kernelzip
