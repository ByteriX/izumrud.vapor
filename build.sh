
#
#  build.sh
#  version 2.0.1
#
#  Created by Sergey Balalaev on 20.08.15.
#  Copyright (c) 2015-2021 ByteriX. All rights reserved.
#

PROJECT_NAME=""
CONFIGURATION_NAME="Release"
SCHEME_NAME=""
SETUP_VERSION=auto
IS_PODS_INIT=false
IS_TAG_VERSION=false
OUTPUT_NAME=""

EXPORT_PLIST=""
PROVISIONING_PROFILE="" #reserver

USERNAME=""
PASSWORD=""

# get parameters of script

POSITIONAL=()

#if [ "$#" -le 3 ] && [ "$1" != "-h" ]; then
#    echo -e '\nSomething is missing... Type "./build -h" without the quotes to find out more...\n'
#    exit 0
#fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--project)
    PROJECT_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--configuration)
    CONFIGURATION_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--scheme)
    SCHEME_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--user)
    USERNAME="$2"
    PASSWORD="$3"
    if [ PASSWORD == "" ]; then
        echo "ERROR: $1 need 2 parameters"
        exit
    fi
    shift # past argument
    shift # past value 1
    shift # past value 2
    ;;
    -v|--version)
    SETUP_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output)
    OUTPUT_NAME=$2
    shift # past argument
    shift # past value
    ;;
    -e|--export)
    EXPORT_PLIST="$2"
    shift # past argument
    shift # past value
    ;;
    -ip|--initpods)
    IS_PODS_INIT=true
    shift # past argument
    shift # past value
    ;;
    -at|--addtag)
    IS_TAG_VERSION=true
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo ""
    echo "Help for call build script with parameters:"
    echo "  -p, --project : name of project or workspase. Requered param."
    echo "  -t, --target  : name of target. Default is project name."
    echo "  -e, --export  : export plist file. Default is AdHoc.plist or AppStore.plist when defined -u/--user"
    echo ""
    echo "Emample: sh build.sh -p ProjectName -ip -t --version auto\n\n"
    exit 0
    ;;
    *)
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Common Settings


# Initalize

APP_BUILD_PATH="${PWD}/.build"
BUILD_DIR="${APP_BUILD_PATH}/xcode"
APP_CURRENT_BUILD_PATH="${APP_BUILD_PATH}/Current"
APP_CONFIG_PATH="./build.config"
BUILD_VERSION_TAG_GROUP_NAME="build"
PROJECT_PLIST="${PROJECT_NAME}/Resources/Plists/Info.plist"

# Setup skiped parameters init

if [ "$PROJECT_NAME" == "" ]; then
    echo "ERROR: Expected project name from build parameters. Please read the help (call with -h or -help)."
    exit 1
fi
if [ "$SCHEME_NAME" == "" ]; then
    SCHEME_NAME=$PROJECT_NAME
fi
if [ "$OUTPUT_NAME" == "" ]; then
    OUTPUT_NAME="${SCHEME_NAME}"
fi
if [ "$EXPORT_PLIST" == "" ]; then
    if [ "$USERNAME" == "" ]; then
        EXPORT_PLIST="./AdHoc.plist"
    else
        EXPORT_PLIST="./AppStore.plist"
    fi
fi

# Setup version

if [ "$SETUP_VERSION" == "auto" ]; then
    echo "Pulling all tags from remote"
    #git pull --tags
    git fetch --tags
        
    # get templated version number as max from git tags:
    VERSION_TAG=$(git describe --tags $(git rev-list --tags=${BUILD_VERSION_TAG_GROUP_NAME}/* --max-count=1000) | awk "/$BUILD_VERSION_TAG_GROUP_NAME\/[0-9.]+$"'/{print $0}' | sed -n "s/$BUILD_VERSION_TAG_GROUP_NAME\/\(\S*\)/\1/p" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print max}')
    echo "Last tag version is $VERSION_TAG\n"

    if [[ $VERSION_TAG =~ ^[0-9]+$ ]]
    then
        VERSION_TAG=$((VERSION_TAG+1))
    else
        VERSION_TAG=1
    fi
    echo "Auto detect version has value: $VERSION_TAG\n"
    echo "CURRENT_PROJECT_VERSION=$VERSION_TAG" > "$APP_CONFIG_PATH"
else
    echo "CURRENT_PROJECT_VERSION=$SETUP_VERSION" > "$APP_CONFIG_PATH"
fi

. "$APP_CONFIG_PATH"

# Create execution

checkExit(){
    if [ $? != 0 ]; then
        echo "Building failed\n"
        exit 1
    fi
}

# Functions

clearCurrent(){
    rm -r -f -d "${APP_CURRENT_BUILD_PATH}"
}

createIPA()
{
    local CONFIGURATION_NAME=$1
    local SCHEME_NAME=$2
    local EXPORT_PLIST=$3
    local PROVISIONING_PROFILE=$4

    ACTION="clean archive"
    APP="${BUILD_DIR}/${CONFIGURATION_NAME}-iphoneos/${PROJECT_NAME}.app"
    ARCHIVE_PATH="${BUILD_DIR}/${SCHEME_NAME}.xcarchive"
    
    rm -rf "${BUILD_DIR}"

    if [ -d "${PROJECT_NAME}.xcworkspace" ]; then
        XCODE_PROJECT="-workspace ${PROJECT_NAME}.xcworkspace"
        echo "Start for workspace!!!\n"
    else
        XCODE_PROJECT="-project ${PROJECT_NAME}.xcodeproj"
        echo "Start for workspace!!!\n"
    fi
    
    PROVISIONING_PROFILE_PARAMS=""
    if [ "${PROVISIONING_PROFILE}" != "" ]; then
        PROVISIONING_PROFILE_PARAMS="PROVISIONING_PROFILE=${PROVISIONING_PROFILE}"
    fi
    
    xcodebuild \
    -allowProvisioningUpdates \
    -configuration ${CONFIGURATION_NAME} $XCODE_PROJECT \
    -scheme ${SCHEME_NAME} \
    -sdk iphoneos \
    -xcconfig "${APP_CONFIG_PATH}" BUILD_DIR="${BUILD_DIR}" \
    -archivePath "${ARCHIVE_PATH}" $PROVISIONING_PROFILE_PARAMS $ACTION
    
    checkExit
    echo "Creating .ipa for ${APP} ${APP_CURRENT_BUILD_PATH} ${SIGNING_IDENTITY} ${PROVISIONING_PROFILE}\n"
    clearCurrent

    xcodebuild \
    -allowProvisioningUpdates \
    -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${EXPORT_PLIST}" \
    -exportPath "${APP_CURRENT_BUILD_PATH}"
    
    checkExit
    echo "Created .ipa for ${PROJECT_NAME}\n"

}

createIpaAndSave(){
    local CONFIGURATION_NAME=$1
    local SCHEME_NAME=$2
    local EXPORT_PLIST=$3
    local PROVISIONING_PROFILE=$4

    createIPA "${CONFIGURATION_NAME}" "${SCHEME_NAME}" "${EXPORT_PLIST}" "${PROVISIONING_PROFILE}"

    RESULT_DIR=${APP_BUILD_PATH}/${SCHEME_NAME}
    IPA_FILES=( ${APP_CURRENT_BUILD_PATH}/*.ipa )
    IPA_FILE=${IPA_FILES[0]}
    echo "Found builded ipa file: ${IPA_FILE}"
    IPA_PATH="${RESULT_DIR}/${OUTPUT_NAME}.ipa"
    
    rm -f -d -r "${RESULT_DIR}"
    mkdir -p "${RESULT_DIR}"
    cp "${IPA_FILE}" "${IPA_PATH}"
    
    checkExit

    echo "IPA saved to ${IPA_PATH}"
}

tagCommit(){
	git tag -f -a "${BUILD_VERSION_TAG_GROUP_NAME}/${CURRENT_PROJECT_VERSION}" -m build
	git push -f --tags
    checkExit
    echo "Tag addition complete"
}

 #reserved
copyToDownload(){
    # create plist for download
    local VERSION_NAME=`plutil -p "${PROJECT_PLIST}" | grep "CFBundleShortVersionString.*$ApplicationVersionNumber"`
    local VERSION=$(echo $VERSION_NAME | grep -o '"[[:digit:].]*"' | sed 's/"//g')

    APP_PLIST_PATH="${RESULT_DIR}/${OUTPUT_NAME}.plist"

    sed "s/CURRENT_PROJECT_VERSION/${VERSION}/" build_result.plist > "${APP_PLIST_PATH}"

    checkExit

    local SERVER_PATH="${HOME}/Projects/vapor"
    local SERVER_DOWNLOAD_PATH="${SERVER_PATH}/Public/download"
    
    cp -f "${APP_CURRENT_BUILD_PATH}/${PROJECT_NAME}.plist" "${SERVER_DOWNLOAD_PATH}/${PROJECT_NAME}.plist"
    cp -f "${APP_CURRENT_BUILD_PATH}/${PROJECT_NAME}.ipa" "${SERVER_DOWNLOAD_PATH}/${PROJECT_NAME}.ipa"
}

podSetup(){
	if [ -f Podfile.lock ]; then
		rm -rf ~/Library/Caches/CocoaPods
		rm -rf Pods
	    pod install --repo-update
	    checkExit
	elif [ -f Podfile ]; then
		pod update
		checkExit
	fi
}

uploadToStore(){
    xcrun altool --upload-app -f "${IPA_PATH}" -u $USERNAME -p $PASSWORD
    checkExit
    echo "Application uploading finished with success"
}

if $IS_PODS_INIT ; then
    echo "Starting pod init:"
    podSetup
    checkExit
fi

# General part of building:

echo "Starting build script with parameters:"
echo "PROJECT_NAME         = ${PROJECT_NAME}"
echo "CONFIGURATION_NAME = ${CONFIGURATION_NAME}"
echo "SCHEME_NAME          = ${SCHEME_NAME}"
echo "OUTPUT_NAME          = ${OUTPUT_NAME}"
cat "$APP_CONFIG_PATH"

createIpaAndSave "${CONFIGURATION_NAME}" "${SCHEME_NAME}" "${EXPORT_PLIST}" "${PROVISIONING_PROFILE}"

if [ "$USERNAME" != "" ] ; then
    echo ""
    echo "Starting upload to store:"
    echo "USERNAME          = ${USERNAME}"
    echo "PASSWORD          = ${PASSWORD}"

    uploadToStore
fi

if $IS_TAG_VERSION ; then
    echo "Starting addition tag:"
    tagCommit
fi
