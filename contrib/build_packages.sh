#!/bin/bash

if [ ! -e bin/WNRG ]; then
	echo "Call from the main SOURCE directory, with GreatSPN fully built"
	exit 1
fi

GREATSPN_APP_VERSION_MAJOR=3
GREATSPN_APP_VERSION_MINOR=1
GREATSPN_APP_VERSION=v${GREATSPN_APP_VERSION_MAJOR}r${GREATSPN_APP_VERSION_MINOR}
GREATSPN_APP_VERSION_NUMDOT=${GREATSPN_APP_VERSION_MAJOR}.${GREATSPN_APP_VERSION_MINOR}
GREATSPN_APP_VERSION_FULLNUMBER=`expr ${GREATSPN_APP_VERSION_MAJOR}00 + ${GREATSPN_APP_VERSION_MINOR}`
GREATSPN_APPNAME=GreatSPN
GREATSPN_APPNAME_LOWERCASE=greatspn
GREATSPN_APPNAME_ID=greatspn-${GREATSPN_APP_VERSION}

OBJECT_ROOTDIR=objects/AppImage

echo "Building ${GREATSPN_APPNAME} version ${GREATSPN_APP_VERSION_FULLNUMBER}"

# jdeps --ignore-missing-deps --print-module-deps \
# 			--class-path ${OBJDIR}/JavaGUI/bin/lib/*.jar \
# 			${OBJDIR}/JavaGUI/bin/Editor.jar
JAVAGUI_MODULES=java.base,java.compiler,java.desktop,java.naming,java.prefs,java.sql

# Determine OS-dependent parameters.
case "$OSTYPE" in
#----------------------------------------------------------
darwin*)
echo "Running on OSX"
# macOS jpackage directory structure:
# 		HelloWorld.app/
# 		  Contents/
# 		    Info.plist
# 		    MacOS/               // Application launchers
# 		      HelloWorld
# 		    Resources/           // Icons, etc.
# 		    app/
# 		      HelloWorld.cfg     // Configuration info, created by jpackage
# 		      HelloWorld.jar     // JAR file, copied from the --input directory
# 		    runtime/             // Java runtime image
JPACKAGE_OPTIONS="
	--java-options \"-Djava.library.path=Contents/Java/\" 
	--java-options \"-Dapple.laf.useScreenMenuBar=true\" 
	--java-options \"-Dcom.apple.macos.useScreenMenuBar=true\" 
	--file-associations JavaGUI/AdditionalV3/PNPRO-macos-FileAssoc.txt \
	--icon JavaGUI/AdditionalV3/GreatSPN.icns
	--mac-package-identifier \"${GREATSPN_APPNAME_ID}\"
	"
OBJECT_APPIMAGE_DIR=${OBJECT_ROOTDIR}/${GREATSPN_APPNAME}.app
# APPDIR is the same variable used by the native launcher in the GreatSPN.cfg file
APPDIR=${OBJECT_APPIMAGE_DIR}/Contents/app
;;

#----------------------------------------------------------
linux*)
echo "Running on LINUX"
# Linux jpackage directory structure:
# 		myapp/
# 		  bin/              // Application launchers
# 		    HelloWorld
# 		  lib/
# 		    app/
# 		      HelloWorld.cfg     // Configuration info, created by jpackage
# 		      HelloWorld.jar     // JAR file, copied from the --input directory
# 		    runtime/             // Java runtime image
JPACKAGE_OPTIONS="
	--icon JavaGUI/AdditionalV3/GreatSPN.png
	--file-associations JavaGUI/AdditionalV3/PNPRO-linux-FileAssoc.txt \
	"
OBJECT_APPIMAGE_DIR=${OBJECT_ROOTDIR}/${GREATSPN_APPNAME}
APPDIR=${OBJECT_APPIMAGE_DIR}/lib/app
;;

#----------------------------------------------------------
cygwin*)
# Windows jpackage directory structure:
# 		HelloWorld/
# 		  HelloWorld.exe       // Application launchers
# 		  app/
# 		    HelloWorld.cfg     // Configuration info, created by jpackage
# 		    HelloWorld.jar     // JAR file, copied from the --input directory
# 		  runtime/             // Java runtime image
echo "Running on CYGWIN"
JPACKAGE_OPTIONS="
	--icon JavaGUI/AdditionalV3/GreatSPN.ico
	--file-associations JavaGUI/AdditionalV3/PNPRO-win-FileAssoc.txt \
	"
# --java-options -Dsun.java2d.uiScale.enabled=false
# --java-options -Dsun.java2d.uiScale=2.0
# --java-options -Dsun.java2d.win.uiScaleX=2.0 
# --java-options -Dsun.java2d.win.uiScaleY=2.0
OBJECT_APPIMAGE_DIR=${OBJECT_ROOTDIR}/${GREATSPN_APPNAME}
APPDIR=${OBJECT_APPIMAGE_DIR}/app
;;

#----------------------------------------------------------
*)        
echo "unknown: $OSTYPE"
exit 1 
;;
esac


###########################################################
echo 'FIRST STAGE: Building the app-image'

rm -rf ${OBJECT_ROOTDIR}
mkdir -p ${OBJECT_ROOTDIR}
jpackage \
	--type app-image \
	--input JavaGUI/Editor/dist \
	--name ${GREATSPN_APPNAME} \
	--main-jar Editor.jar \
	--main-class editor.Main \
	--add-modules ${JAVAGUI_MODULES} \
	--resource-dir JavaGUI/AdditionalV3 \
	--java-options -enableassertions \
	--java-options '"-splash:$APPDIR/splash.png"' \
	--app-version "${GREATSPN_APP_VERSION_FULLNUMBER}" \
	--copyright "University of Torino, Italy" \
	--description "The GreatSPN framework. Visit https://github.com/greatspn/SOURCES for more informations." \
	--dest ${OBJECT_ROOTDIR} \
	${JPACKAGE_OPTIONS}
RET=$? ; if [ ${RET} -eq 1 ]; then exit ${RET} ; fi

###########################################################
echo 'SECOND STAGE: Creating the Portable GreatSPN distribution'

mkdir -p ${APPDIR}/portable_greatspn
mkdir -p ${APPDIR}/portable_greatspn/bin
mkdir -p ${APPDIR}/portable_greatspn/lib

cp bin/* ${APPDIR}/portable_greatspn/bin/
rm -f ${APPDIR}/portable_greatspn/bin/DSPN-Tool-Debug # not needed

cp JavaGUI/AdditionalV3/splash.png ${APPDIR}/

case "$OSTYPE" in
#----------------------------------------------------------
darwin*)
cp  ../meddly/src/.libs/libmeddly.dylib \
    ../spot-2.9.6/spot/.libs/libspot.dylib \
    ../spot-2.9.6/buddy/src/.libs/libbddx.dylib \
    ${APPDIR}/portable_greatspn/lib/
;;

#----------------------------------------------------------
linux*)   
cp  ../meddly/src/.libs/libmeddly.so.0 \
    ../spot-2.9.6/spot/.libs/libspot.so.0 \
    ../spot-2.9.6/buddy/src/.libs/libbddx.so.0 \
    ${APPDIR}/portable_greatspn/lib/
;;

#----------------------------------------------------------
cygwin*) 
# derived using ldd bin/RGMEDD5 & other
# NOTE: everything will be in the bin/ directory in windows
cp  /usr/bin/cygwin1.dll \
	/usr/bin/cyggmp-10.dll \
	/usr/bin/cyggcc_s-seh-1.dll \
	/usr/bin/cyggmpxx-4.dll \
	/usr/local/bin/cygspot-0.dll \
	/usr/local/bin/cygbddx-0.dll \
	/usr/bin/cygstdc++-6.dll \
	${APPDIR}/portable_greatspn/bin/
;;

#----------------------------------------------------------
*)        
echo "unknown: $OSTYPE"
exit 1 
;;
esac

###########################################################
echo 'THIRD STAGE: Creating installable packages'

# exit

case "$OSTYPE" in
#----------------------------------------------------------
darwin*)
# Make the DMG package
jpackage \
	--type dmg \
	--app-image ${OBJECT_APPIMAGE_DIR} \
	--name ${GREATSPN_APPNAME} \
	--app-version "${GREATSPN_APP_VERSION_FULLNUMBER}" \
	--file-associations JavaGUI/AdditionalV3/PNPRO-macos-FileAssoc.txt \
	--resource-dir JavaGUI/AdditionalV3 \
	--mac-package-name "${GREATSPN_APPNAME}-${GREATSPN_APP_VERSION_FULLNUMBER}" \
	--mac-package-identifier "${GREATSPN_APPNAME_ID}"

OLDDMG=${GREATSPN_APPNAME}-${GREATSPN_APP_VERSION_FULLNUMBER}.dmg
NEWDMG=${GREATSPN_APPNAME}-${GREATSPN_APP_VERSION_NUMDOT}-macOS-`uname -m`.dmg
mv ${OLDDMG} ${NEWDMG}

;;

#----------------------------------------------------------
linux*)   
# Make installable DEB package
# Application icon is taken from the resource-dir directory
jpackage \
	--type deb \
	--app-image ${OBJECT_APPIMAGE_DIR} \
	--name ${GREATSPN_APPNAME} \
	--app-version ${GREATSPN_APP_VERSION_FULLNUMBER} \
	--file-associations JavaGUI/AdditionalV3/PNPRO-linux-FileAssoc.txt \
	--resource-dir JavaGUI/AdditionalV3 \
	--linux-deb-maintainer "Elvio Amparore <amparore@di.unito.it>" \
	--linux-menu-group "Science" \
	--linux-app-release "full" \
	--linux-package-deps "libsuitesparse-dev, libgmpxx4ldbl, libgmp-dev, graphviz"

OLDDEB=`ls ${GREATSPN_APPNAME_LOWERCASE}_${GREATSPN_APP_VERSION_FULLNUMBER}*.deb`
NEWDEB=`echo ${OLDDEB} | sed "s/${GREATSPN_APP_VERSION_FULLNUMBER}-full/${GREATSPN_APP_VERSION_NUMDOT}-linux/g"`
mv ${OLDDEB} ${NEWDEB}

# Make installable RPM package
jpackage \
	--type rpm \
	--app-image ${OBJECT_APPIMAGE_DIR} \
	--name ${GREATSPN_APPNAME} \
	--app-version ${GREATSPN_APP_VERSION_FULLNUMBER} \
	--file-associations JavaGUI/AdditionalV3/PNPRO-linux-FileAssoc.txt \
	--resource-dir JavaGUI/AdditionalV3 \
	--linux-menu-group "Science" \
	--linux-app-release "full" \
	--linux-package-deps "gmp-c++, gmp, suitesparse, graphviz, lpsolve"

OLDRPM=`ls ${GREATSPN_APPNAME_LOWERCASE}-${GREATSPN_APP_VERSION_FULLNUMBER}*.rpm`
NEWRPM=`echo ${OLDRPM} | sed "s/${GREATSPN_APP_VERSION_FULLNUMBER}-full/${GREATSPN_APP_VERSION_NUMDOT}-linux/g"`
mv ${OLDRPM} ${NEWRPM}

;;

#----------------------------------------------------------
cygwin*)
# Make the MSI installer
jpackage \
	--type msi \
	--app-image ${OBJECT_APPIMAGE_DIR} \
	--name ${GREATSPN_APPNAME} \
	--app-version ${GREATSPN_APP_VERSION_NUMDOT} \
	--file-associations JavaGUI/AdditionalV3/PNPRO-win-FileAssoc.txt \
	--resource-dir JavaGUI/AdditionalV3 \
	--win-menu --win-menu-group "${GREATSPN_APPNAME}" \
	--win-dir-chooser

echo "TBD: add renaming cmds."
;;

#----------------------------------------------------------
*)        
echo "unknown: $OSTYPE"
exit 1 
;;
esac





###########################################################
echo 'FOURTH STAGE: Cleaning temporary files'

rm -rf ${OBJECT_ROOTDIR}

echo "Done."




















