#!/bin/bash
# Original author of the script : powen
# Modified by "SoftwareRat" for simple SideStore usage on Linux

# Check for all dependencies needed for the script to work
check_dependency() {
    local binary_name=$1
    if ! which "$binary_name" >/dev/null 2>&1; then
        echo "ERROR: $binary_name not found. Please install it and try again."
        exit 1
    fi
}
check_dependency "idevice_id"
check_dependency "usbmuxd"
check_dependency "wget"
check_dependency "curl"

# Check if "sidestore.ipa" exists in the current directory
# If not, exit this script with an error
if [[ ! -f "sidestore.ipa" ]]; then
    echo "ERROR: sidestore.ipa not found. Please download it and try again."
    exit 1
fi

# Execute code part only if the binary "AltServer" does not exist in the current directory
if [[ ! -f "AltServer" ]]; then
    echo "AltServer binary not found. Downloading..."
    ARCH=$(uname -m)
    LATEST_VERSION=$(curl -s https://api.github.com/repos/NyaMisty/AltServer-Linux/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7" || "$ARCH" == "i586" || "$ARCH" == "x86_64" ]]; then
    wget -q https://github.com/NyaMisty/AltServer-Linux/releases/download/$LATEST_VERSION/AltServer-$ARCH -O AltServer
    chmod +x AltServer
    else
    echo "ERROR: Unsupported architecture: $ARCH"
    exit 1
    fi
fi

HasExistAccount=$(cat saved.txt)
# If UDID is not found, then output error and exit
UDID=$(idevice_id -l)
if [[ "$UDID" == "" ]]; then
    echo "ERROR: No iDevice found."
    exit 1
fi
# Execute the code down only if ALTSERVER_ANISETTE_SERVER is not set. If the user says no, use "https://ani.sidestore.io".
# If the user wants an custom anisette server, ask the user to save the URL permanently in .bashrc
if [[ "$ALTSERVER_ANISETTE_SERVER" == "" ]]; then
    echo "Do you want to use a custom anisette server? [y/n]"
    read reply
    case "$reply" in
    [yY][eE][sS]|[yY] )
    echo "Please enter the URL of the anisette server"
    read anisette_server
    export ALTSERVER_ANISETTE_SERVER=$anisette_server
    echo "Do you want to save this URL permanently? [y/n]"
    read reply
    case "$reply" in
    [yY][eE][sS]|[yY] )
    echo "export ALTSERVER_ANISETTE_SERVER=$anisette_server" >> ~/.bashrc
    ;;
    [nN][oO]|[nN] )
    ;;
    esac
    ;;
    [nN][oO]|[nN] )
    export ALTSERVER_ANISETTE_SERVER=https://ani.sidestore.io
    ;;
    esac
fi
# Check if there exists saved account
# Ask if want to use saved account
AskAccount() {
    if [[ "$HasExistAccount" != "" ]]; then
        echo "Do you want to use saved Account? [y/n]"
        read reply
        case "$reply" in
        [yY][eE][sS]|[yY] )
        echo "Which account you want to use? "
        UseExistAccount=1
        nl saved.txt
        echo "Please enter the number "
        read number
        AppleID=$(sed -n "$number"p saved.txt | cut -d , -f 1)
        password=$(sed -n "$number"p saved.txt | cut -d , -f 2)
        ;;
        [nN][oO]|[nN] )
        UseExistAccount=0
        ;;
        esac
    fi
    if [[ "$HasExistAccount" == "" ]]; then
        UseExistAccount=0
    fi
    if [[ $UseExistAccount = 0 ]]; then
        echo "Please provide your AppleID"
        read AppleID
        echo "Please provide the password of AppleID"
        read password
    fi
}

# Execute AltServer
# Check if this account existed before
AltServer() {
    #echo "UDID: $UDID, AppleID: $AppleID, password: $password, IPA_PATH: $IPA_PATH"
    ./AltServer -u ${UDID} -a "$AppleID" -p $password $IPA_PATH
    if [[ "$CheckAccount" == "" ]] ; then
        AccountSaving=1
    fi
}

# Ask to save the new account
SaveAcccount() {
    echo "Do you want to save this account? [y/n]"
    read ans
    case "$ans" in
    [yY][eE][sS]|[yY] )
    echo "$Account" >> saved.txt
    echo "saved"
    ;;
    [nN][oO]|[nN] )
    ;;
    esac
}

# Start main script
AskAccount
Account=$AppleID,$password
CheckAccount=$(grep $Account saved.txt)
IPA_PATH=./sidestore.ipa
AltServer
if [[ $AccountSaving = 1 ]] ; then
    SaveAcccount
fi