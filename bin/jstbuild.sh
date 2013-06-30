#!/bin/bash

# there's a lot of gus specific stuff in here.
SRC_DIR=`cd ${0%/*}/..; pwd`
startDate=`/bin/date`
revision=""
upload=1
ql=1
appStoreSettings=""
archFlags=""
appStore=0
checkout=1


while getopts e:nr:st option
do
        case "${option}"
        in      
            e)
                echoversion=${OPTARG}
                ;;
            n)
                upload=0
                    ;;
            r)
                revision="-r ${OPTARG}"
                upload=0
                ;;
            s)
                appStore=1
                upload=0
                appStoreSettings="-xcconfig AppStore.xcconfig"
                #echo 'CODE_SIGN_IDENTITY=3rd Party Mac Developer Application: Flying Meat Inc.' > AppStore.xcconfig
                echo "OTHER_CFLAGS=-DMAC_APP_STORE" > AppStore.xcconfig
                ;;
            t)
                echo "USING LOCAL TREE"
                checkout=0
                ;;
            
            \?) usage
                echo "invalid option: $1" 1>&2
                exit 1
            ;;
        esac
done




if [ "$echoversion" != "" ]; then
    version=$echoversion
    
    # this is for gus to make distributions with.
    
    echo "cd ~/jstalk/download/"
    echo "cp JSTalkPreview.zip JSTalk-$version.zip"
    echo "rm JSTalk.zip; ln -s JSTalk-$version.zip JSTalk.zip"
    
    exit
fi


buildDate=`/bin/date +"%Y.%m.%d.%H"`

if [ ! -d  ~/cvsbuilds ]; then
    mkdir ~/cvsbuilds
fi

echo cleaning.
rm -rf ~/cvsbuilds/JSTalk*
rm -rf /tmp/jstalk

source ~/.bash_profile
v=`date "+%s"`

if [ $checkout == 1 ]; then

    cd /tmp
    
    echo "doing remote checkout ($revision) upload($upload)"
    git clone git://github.com/ccgus/jstalk.git
    cd jstalk
    git checkout Mocha
else
    echo "Copying local tree"
    cp -r $SRC_DIR /tmp/jstalk
fi

cd /tmp/jstalk

echo setting build id
sed -e "s/BUILDID/$v/g"  res/Info.plist > res/Info.plist.tmp
mv res/Info.plist.tmp res/Info.plist



xcodebuild=/usr/bin/xcodebuild
function buildTarget {
    
    echo Building "$1"
    
    $xcodebuild -target "$1" -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build $appStoreSettings
    
    if [ $? != 0 ]; then
        echo "****** Bad build for $1 ********"
        say "Bad build for $1"
        
    fi
}


buildTarget "JSTalk Framework"
buildTarget "jstalk command line"
buildTarget "JSTalk Editor"


cd /tmp/jstalk/plugins/sqlite-fmdb-jstplugin
$xcodebuild -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS="" -target fmdbextra
if [ $? != 0 ]; then
    echo "****** Bad build for fmdb extra ********"
    exit
fi


cd /tmp/jstalk/plugins/GTMScriptRunner-jstplugin
$xcodebuild -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS=""
if [ $? != 0 ]; then
    echo "****** Bad build for GTMScriptRunner ********"
    exit
fi

cd /tmp/jstalk/automator/
$xcodebuild -configuration Release OBJROOT=/tmp/jstalk/build SYMROOT=/tmp/jstalk/build OTHER_CFLAGS="" -target JSTAutomator
if [ $? != 0 ]; then
    echo "****** Bad build for automator action ********"
    exit
fi


cd /tmp/jstalk/build/Release/

mkdir -p /tmp/jstalk/build/Release/JSTalk\ Editor.app/Contents/Library/Automator
mv /tmp/jstalk/build/Release/JSTalk.action /tmp/jstalk/build/Release/JSTalk\ Editor.app/Contents/Library/Automator/.

if [ ! -d  ~/cvsbuilds ]; then
    mkdir ~/cvsbuilds
fi


mkdir JSTalkFoo

mv jstalk JSTalkFoo/.
mv "JSTalk Editor.app" JSTalkFoo/.

# I do a cp here, since I rely on this framework being here for other builds...
cp -R JSTalk.framework JSTalkFoo/.
cp -R /tmp/jstalk/example_scripts JSTalkFoo/examples
cp -R /tmp/jstalk/plugins/sqlite-fmdb-jstplugin/fmdb.jstalk JSTalkFoo/examples/.

mkdir -p JSTalkFoo/JSTalk\ Editor.app/Contents/PlugIns

#cp -r JSTalk.acplugin       JSTalkFoo/plugins/.
#cp -r JSTalk.vpplugin       JSTalkFoo/plugins/.
cp -r FMDB.jstplugin        JSTalkFoo/JSTalk\ Editor.app/Contents/PlugIns/.
#cp -r ImageTools.jstplugin  JSTalkFoo/JSTalk\ Editor.app/Contents/PlugIns/.
cp -r GTMScriptRunner.jstplugin JSTalkFoo/JSTalk\ Editor.app/Contents/PlugIns/.

mv JSTalkFoo JSTalk

mv JSTalk ~/cvsbuilds/.


if [ $appStore = 1 ]; then
    
    cd ~/cvsbuilds/JSTalk
    
    cd ~/cvsbuilds/JSTalk
    cd JSTalk\ Editor.app/Contents/Frameworks/JSTalk.framework/Versions/A/Resources/
    
    # app loader doesn't like multipe frameworks with the same id in it.
    sed -e "s/org.jstalk.JSTalk/org.jstalk.JSTalkEditor.JSTalkFramework/g"  Info.plist > Info.plist.tmp
    mv Info.plist.tmp Info.plist
    
    cd ~/cvsbuilds/JSTalk
    
    /usr/bin/codesign -f -s "3rd Party Mac Developer Application: Flying Meat Inc." JSTalk\ Editor.app
    
    productbuild --product /tmp/jstalk/res/jstalk_product_definition.plist --component JSTalk\ Editor.app /Applications --sign '3rd Party Mac Developer Installer: Flying Meat Inc.' JSTalkEditor.pkg
    
    open .
    
    exit
fi

cd ~/cvsbuilds

ditto -c -k --sequesterRsrc --keepParent JSTalk JSTalk.zip

rm -rf JSTalk

cp JSTalk.zip $v-JSTalk.zip


if [ $upload == 1 ]; then
    echo uploading to server...
    
    #downloadDir=latest
    
    scp ~/cvsbuilds/JSTalk.zip gus@elvis.mu.org:~/jstalk/download/JSTalkPreview.zip
    #scp /tmp/jstalk/res/jstalkupdate.xml gus@elvis.mu.org:~/fm/download/$downloadDir/.
    #scp /tmp/jstalk/res/shortnotes.html gus@elvis:~/fm/download/$downloadDir/jstalkshortnotes.html
fi

say "done building"

endDate=`/bin/date`
echo Start: $startDate
echo End:   $endDate

echo "(That was version $v)"
