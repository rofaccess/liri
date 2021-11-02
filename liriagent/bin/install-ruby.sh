#!/bin/bash
#
# Resolve the location of the SmartSVN installation.
# This includes resolving any symlinks.
PRG=$0
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
    if expr "$link" : '^/' 2> /dev/null >/dev/null; then
        PRG="$link"
    else
        PRG="`dirname "$PRG"`/$link"
    fi
done

SMARTSVN_BIN=`dirname "$PRG"`

# absolutize dir
oldpwd=`pwd`
cd "${SMARTSVN_BIN}"
SMARTSVN_BIN=`pwd`
cd "${oldpwd}"

ICON_NAME=smartsvn-14
TMP_DIR=`mktemp --directory`
DESKTOP_FILE=$TMP_DIR/smartsvn-14.desktop
cat << EOF > $DESKTOP_FILE
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=SmartSVN 14
Keywords=svn;subversion
GenericName=SVN Client
Type=Application
Categories=Development;RevisionControl
Terminal=false
StartupNotify=true
Exec="$SMARTSVN_BIN/smartsvn.sh"
Icon=$ICON_NAME.png
X-Ayatana-Desktop-Shortcuts=NewWindow;RepositoryBrowser

[NewWindow Shortcut Group]
Name=Open a New Window
Exec="$SMARTSVN_BIN/smartsvn.sh"
TargetEnvironment=Unity

[RepositoryBrowser Shortcut Group]
Name=Open the Repository Browser
Exec="$SMARTSVN_BIN/smartsvn.sh" --repository-browser
TargetEnvironment=Unity
EOF

# seems necessary to refresh immediately:
chmod 644 $DESKTOP_FILE

xdg-desktop-menu install $DESKTOP_FILE
xdg-icon-resource install --size  32 "$SMARTSVN_BIN/smartsvn-32.png"  $ICON_NAME
xdg-icon-resource install --size  48 "$SMARTSVN_BIN/smartsvn-48.png"  $ICON_NAME
xdg-icon-resource install --size  64 "$SMARTSVN_BIN/smartsvn-64.png"  $ICON_NAME
xdg-icon-resource install --size 128 "$SMARTSVN_BIN/smartsvn-128.png" $ICON_NAME

rm $DESKTOP_FILE
rm -R $TMP_DIR
