#!/bin/bash

# there's a lot of gus specific stuff in here.

startDate=`/bin/date`
revision=""
upload=1
ql=1

while [ "$#" -gt 0 ]
do
    case "$1" in
        --revision|-r)
                revision="-r $2"
                upload=0
                break
                ;;
        --noupload|-n)
                upload=0
                break
                ;;
        --echo|-e)
                echoversion="$2"
                break
                ;;
        *)
                echo "$CMDNAME: invalid option: $1" 1>&2
                exit 1
                ;;
    esac
    shift
done


if [ "$echoversion" != "" ]; then
    version=$echoversion
    
    # todo
    
    exit
fi


xcodebuild=/usr/bin/xcodebuild


buildDate=`/bin/date +"%Y.%m.%d.%H"`

if [ ! -d  ~/cvsbuilds ]; then
    mkdir ~/cvsbuilds
fi

echo cleaning.
rm -rf ~/cvsbuilds/JSTalk*
rm -rf /tmp/jstalk

cd /tmp

source ~/.bash_profile

echo "doing remote checkout ($revision) upload($upload)"
svn co $revision https://flycode.googlecode.com/svn/trunk/jstalk jstalk

cd /tmp/jstalk

v=`svnversion -n /tmp/jstalk`

echo setting build id
sed -e "s/BUILDID/$v/g"  res/Info.plist > res/Info.plist.tmp
mv res/Info.plist.tmp res/Info.plist


function buildTarget {
    
    echo Building "$1"
    
    $xcodebuild -target "$1" -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS=""
    
    if [ $? != 0 ]; then
        echo "****** Bad build for $1 ********"
        say "Bad build for $1"
        exit
    fi
}


buildTarget "JSTalk Framework"
buildTarget "jstalk command line"
buildTarget "JSTalkRunner"
buildTarget "JSTalk Editor"




cd /tmp/jstalk/extras/acornplugin
xcodebuild -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS=""
if [ $? != 0 ]; then
    echo "****** Bad build for acorn plugin ********"
    exit
fi

cd /tmp/jstalk/extras/voodoopadplugin
xcodebuild -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS=""
if [ $? != 0 ]; then
    echo "****** Bad build for vp plugin ********"
    exit
fi



if [ ! -d  ~/cvsbuilds ]; then
    mkdir ~/cvsbuilds
fi

cd /tmp/jstalk/build/Release/

mkdir JSTalkFoo

mv jstalk JSTalkFoo/.
mv "JSTalk Editor.app" JSTalkFoo/.

# I do a cp here, since I rely on this framework being here for other builds...
cp -R JSTalk.framework JSTalkFoo/.
cp -R /tmp/jstalk/README.txt JSTalkFoo/.
cp -R /tmp/jstalk/example_scripts JSTalkFoo/examples

mkdir JSTalkFoo/extras
mv JSTalk.acplugin JSTalkFoo/extras/.
mv JSTalk.vpplugin JSTalkFoo/extras/.


mv JSTalkFoo JSTalk

ditto -c -k --sequesterRsrc --keepParent JSTalk JSTalk.zip

rm -rf JSTalk

mv JSTalk.zip ~/cvsbuilds/.

cd ~/cvsbuilds/

cp JSTalk.zip $v-JSTalk.zip


if [ $upload == 1 ]; then
    echo uploading to server...
    
    downloadDir=private
    
    scp ~/cvsbuilds/JSTalk.zip gus@elvis.mu.org:~/fm/download/$downloadDir/JSTalkPreview.zip
    #scp /tmp/jstalk/res/jstalkupdate.xml gus@elvis.mu.org:~/fm/download/$downloadDir/.
    #scp /tmp/jstalk/res/shortnotes.html gus@elvis:~/fm/download/$downloadDir/jstalkshortnotes.html
fi

say "done building"

endDate=`/bin/date`
echo Start: $startDate
echo End:   $endDate

echo "(That was version $v)"
