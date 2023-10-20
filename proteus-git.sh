#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
echo 

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Proteus Apt Git
#   @when   :           2023-10-19 15:24:32
#   @url    :           https://github.com/Aetherinox/proteus-git
#
#   requires chmod +x proteus_git.sh
#
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   vars > colors
#
#   tput setab  [1-7]       – Set a background color using ANSI escape
#   tput setb   [1-7]       – Set a background color
#   tput setaf  [1-7]       – Set a foreground color using ANSI escape
#   tput setf   [1-7]       – Set a foreground color
##--------------------------------------------------------------------------

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
ORANGE=$(tput setaf 208)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 156)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
PINK=$(tput setaf 200)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

##--------------------------------------------------------------------------
#   vars > status messages
##--------------------------------------------------------------------------

STATUS_MISS="${BOLD}${GREYL} MISS ${NORMAL}"
STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${NORMAL}"

##--------------------------------------------------------------------------
#   vars > app
##--------------------------------------------------------------------------

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)
app_dir_home="$HOME/bin"
app_file_this=$(basename "$0")
app_file_proteus="${app_dir_home}/proteus-git"
app_repo_author="Aetherinox"
app_title="Proteus Apt Git"
app_ver=("1" "0" "0" "0")
app_repo="proteus-git"
app_repo_branch="main"
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${app_repo_author}/${app_repo}"
app_mnfst="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/${app_repo_branch}/manifest.json"
app_script="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/BRANCH/setup.sh"
app_dir=$PWD
app_dir_storage="$app_dir/incoming/autodownloader/${sys_code}"
app_pid_spin=0
app_pid=$BASHPID
app_queue_url=()
app_i=0

##--------------------------------------------------------------------------
#   exports
##--------------------------------------------------------------------------

export DATE=$(date '+%Y%m%d')
export YEAR=$(date +'%Y')
export TIME=$(date '+%H:%M:%S')
export ARGS=$1
export LOGS_DIR="$app_dir/logs"
export LOGS_FILE="$LOGS_DIR/proteus-git-${DATE}.log"
export SECONDS=0

##--------------------------------------------------------------------------
#   vars > general
##--------------------------------------------------------------------------

gui_about="Internal system to Proteus App Manager which grabs debian packages."

##--------------------------------------------------------------------------
#   distro
#
#   returns distro information.
##--------------------------------------------------------------------------

# freedesktop.org and systemd
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    OS_VER=$VERSION_ID

# linuxbase.org
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)

# versions of Debian/Ubuntu without lsb_release cmd
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    OS_VER=$DISTRIB_RELEASE

# older Debian/Ubuntu/etc distros
elif [ -f /etc/debian_version ]; then
    OS=Debian
    OS_VER=$(cat /etc/debian_version)

# fallback: uname, e.g. "Linux <version>", also works for BSD
else
    OS=$(uname -s)
    OS_VER=$(uname -r)
fi

##--------------------------------------------------------------------------
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
##--------------------------------------------------------------------------

get_version()
{
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

##--------------------------------------------------------------------------
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
##--------------------------------------------------------------------------

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

##--------------------------------------------------------------------------
#   options
#
#       -d      developer mode
#       -h      help menu
#       -n      developer: null run
#       -s      silent mode | logging disabled
#       -t      theme
##--------------------------------------------------------------------------

opt_usage()
{
    echo
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GRAY}${gui_about}${NORMAL}\n" 1>&2
    echo
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-s${NORMAL}] [${GREYL}-t THEME${NORMAL}] [${GREYL}-v${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-i, --install" "install app from cli" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${DEVGREY}-i \"members\"${NORMAL}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --njs-ver" "specify nodejs version to install" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${DEVGREY}-i \"NodeJS\" --njs-ver 18${NORMAL}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "dev: null run" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-s, --silent" "silent mode which disables logging" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_proteus} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --branch" "branch to update from" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    echo
    echo
    exit 1
}

OPT_APPS_CLI=()

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -b*|--branch*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_BRANCH="${1#*=}"
            if [ -z "${OPT_BRANCH}" ]; then
                echo -e "  ${NORMAL}Must specify a valid branch"
                echo -e "  ${NORMAL}      Default:  ${YELLOW}${app_repo_branch}${NORMAL}"

                exit 1
            fi
            ;;

    -i*|--install*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_APP="${1#*=}"
            OPT_APPS_CLI+=("${OPT_APP}")
            ;;

    -n|--nullrun)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA}${BLINK}Devnull Enabled${NORMAL}"
            ;;

    -s|--silent)
            OPT_NOLOG=true
            echo -e "  ${FUCHSIA}${BLINK}Logging Disabled{NORMAL}"
            ;;

    -u|--update)
            OPT_UPDATE=true
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${NORMAL} - v$(get_version)${NORMAL}"
            echo -e "  ${LGRAY}${BOLD}${app_repo_url}${NORMAL}"
            echo -e "  ${LGRAY}${BOLD}${OS} | ${OS_VER}${NORMAL}"
            echo
            exit 1
            ;;
    *)
            opt_usage
            ;;
  esac
  shift
done

##--------------------------------------------------------------------------
#   vars > active repo branch
##--------------------------------------------------------------------------

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

##--------------------------------------------------------------------------
#   line > comment
#
#   comment REGEX FILE [COMMENT-MARK]
#   comment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_comment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)($regx):\\1$mark\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   line > uncomment
#
#   uncomment REGEX FILE [COMMENT-MARK]
#   uncomment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_uncomment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)[$mark]+[ ]?([ ]*$regx):\\1\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   func > logs > begin
##--------------------------------------------------------------------------

Logs_Begin()
{
    if [ $OPT_NOLOG ] ; then
        echo
        echo
        printf '%-70s %-5s' "    Logging for this package has been disabled." ""
        echo
        echo
        sleep 3
    else
        mkdir -p $LOGS_DIR
        LOGS_PIPE=${LOGS_FILE}.pipe

        # get name of display in use
        local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

        # get user using display
        local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

        if ! [[ -p $LOGS_PIPE ]]; then
            mkfifo -m 775 $LOGS_PIPE
            printf "%-70s %-5s\n" "${TIME}      Creating new pipe ${LOGS_PIPE}" | tee -a "${LOGS_FILE}" >/dev/null
        fi

        LOGS_OBJ=${LOGS_FILE}
        exec 3>&1
        tee -a ${LOGS_OBJ} <$LOGS_PIPE >&3 &
        app_pid_tee=$!
        exec 1>$LOGS_PIPE
        PIPE_OPENED=1

        printf "%-70s %-5s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-70s %-5s\n" "${TIME}      Software  : ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-70s %-5s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-70s %-5s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-70s %-5s\n" "${TIME}      OS        : ${OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-70s %-5s\n" "${TIME}      OS VER    : ${OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-70s %-5s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-70s %-5s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

    fi
}

##--------------------------------------------------------------------------
#   func > logs > finish
##--------------------------------------------------------------------------

Logs_Finish()
{
    if [ ${PIPE_OPENED} ] ; then
        exec 1<&3
        sleep 0.2
        ps --pid $app_pid_tee >/dev/null
        if [ $? -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
            sleep 1
            kill $app_pid_tee >> $LOGS_FILE 2>&1
        fi

        printf "%-70s %-15s\n" "${TIME}      Destroying Pipe ${LOGS_PIPE} (${app_pid_tee})" | tee -a "${LOGS_FILE}" >/dev/null

        rm $LOGS_PIPE
        unset PIPE_OPENED
    fi

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    printf "%-70s %-15s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-70s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null

    sudo pkill -9 -f ".$LOGS_FILE." >> $LOGS_FILE 2>&1
}

##--------------------------------------------------------------------------
#   Begin Logging
##--------------------------------------------------------------------------

Logs_Begin

##--------------------------------------------------------------------------
#   Cache Sudo Password
#
#   require normal user sudo authentication for certain actions
##--------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "\n%-70s %-5s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-70s %-5s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-70s %-5s\n\n" "${TIME}      SUDO [EXISTING]: $USER" | tee -a "${LOGS_FILE}" >/dev/null
    fi
fi

##--------------------------------------------------------------------------
#   func > spinner animation
##--------------------------------------------------------------------------

spin()
{
    spinner="-\\|/-\\|/"

    while :
    do
        for i in `seq 0 7`
        do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.4
        done
    done
}

##--------------------------------------------------------------------------
#   func > spinner > halt
##--------------------------------------------------------------------------

spinner_halt()
{
    if ps -p $app_pid_spin > /dev/null
    then
        kill -9 $app_pid_spin 2> /dev/null
        printf "\n%-70s %-5s\n" "${TIME}      KILL Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
    fi
}

##--------------------------------------------------------------------------
#   func > cli selection menu
##--------------------------------------------------------------------------

cli_options()
{
    opts_show()
    {
        local it=$( echo $1 )
        for i in ${!CHOICES[*]}; do
            if [[ "$i" == "$it" ]]; then
                tput rev
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
                tput sgr0
            else
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
            fi
            tput cuf 2
        done
    }

    tput civis
    it=0
    tput cuf 2

    opts_show $it

    while true; do
        read -rsn1 key
        local escaped_char=$( printf "\u1b" )
        if [[ $key == $escaped_char ]]; then
            read -rsn2 key
        fi

        tput cuu ${#CHOICES[@]} && tput ed
        tput sc

        case $key in
            '[A' | '[C' )
                it=$(($it-1));;
            '[D' | '[B')
                it=$(($it+1));;
            '' )
                return $it && exit;;
        esac

        local min_len=0
        local farr_len=$(( ${#CHOICES[@]}-1))
        if [[ "$it" -lt "$min_len" ]]; then
            it=$(( ${#CHOICES[@]}-1 ))
        elif [[ "$it" -gt "$farr_len"  ]]; then
            it=0
        fi

        opts_show $it

    done
}

##--------------------------------------------------------------------------
#   func > cli question
#
#   used for command-line to prompt the user with a question
##--------------------------------------------------------------------------

cli_question( )
{
    local syntax def response

    while true; do

        # end argument determines type of syntax
        if [ "${2:-}" = "Y" ]; then
            syntax="Y / n"
            def=Y
        elif [ "${2:-}" = "N" ]; then
            syntax="y / N"
            def=N
        else
            syntax="Y / N"
            def=
        fi

        #printf '%-60s %13s %-5s' "    $1 " "${YELLOW}[$syntax]${NORMAL}" ""
        echo -n "$1 [$syntax] "

        read response </dev/tty

        # NULL response uses default
        if [ -z "$response" ]; then
            response=$def
        fi

        # validate response
        case "$response" in
            Y|y|yes|YES)
                return 0
                ;;
            N|n|no|NO)
                return 1
                ;;
        esac

    done
}

##--------------------------------------------------------------------------
#   func > open url
#
#   opening urls in bash can be wonky as hell. just doing it the manual
#   way to ensure a browser gets opened.
##--------------------------------------------------------------------------

open_url()
{
   local URL="$1"
   xdg-open $URL || firefox $URL || sensible-browser $URL || x-www-browser $URL || gnome-open $URL
}

##--------------------------------------------------------------------------
#   func > begin action
##--------------------------------------------------------------------------

begin()
{
    # start spinner
    spin &

    # spinner PID
    app_pid_spin=$!

    printf "%-70s %-5s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 $app_pid_spin 2> /dev/null" `seq 0 15`

    printf '%-70s %-5s' "  ${1}" ""

    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
##--------------------------------------------------------------------------

finish()
{
    arg1=${1}

    spinner_halt

    # if arg1 not empty
    if ! [ -z "${arg1}" ]; then
        assoc_uri="${get_docs_uri[$arg1]}"
        app_queue_url+=($assoc_uri)
    fi
}

##--------------------------------------------------------------------------
#   func > exit action
##--------------------------------------------------------------------------

exit()
{
    finish
    clear
}

##--------------------------------------------------------------------------
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
#
#   proteus-aptget.sh will house the path needed for the script to run
#   anywhere with an entry similar to:
#
#       export PATH="/home/aetherinox/bin:$PATH"
##--------------------------------------------------------------------------

envpath_add()
{
    local file_env=/etc/profile.d/proteus-git.sh
    if [ "$2" = "force" ] || ! echo $PATH | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee $file_env > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee $file_env > /dev/null
        fi
    fi
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

app_update()
{
    local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
    local branch_uri="${app_script/BRANCH/"$repo_branch"}"
    local IsSilent=${2}

    begin "Updating from branch [${repo_branch}]"

    sleep 1
    echo

    printf '%-70s %-5s' "    |--- Downloading update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-70s %-5s' "    |--- Set ownership to ${USER}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-70s %-5s' "    |--- Set perms to u+x" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    echo

    sleep 2
    echo -e "  ${BOLD}${GREEN}Update Complete!${NORMAL}" >&2
    sleep 2

    finish
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

if [ "$OPT_UPDATE" = true ]; then
    app_update ${app_repo_branch_sel}
fi

##--------------------------------------------------------------------------
#   func > first time setup
#
#   this is the default func executed when script is launched to make sure
#   end-user has all the required libraries.
#
#   since we're working on other distros, add curl and wget into the mix
#   since some distros don't include these.
#
#   [ GPG KEY / APT REPO ]
#
#   NOTE:   can be removed via:
#               sudo rm -rf /etc/apt/sources.list.d/aetherinox*list
#
#           gpg ksy stored in:
#               /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
#               sudo rm -rf /usr/share/keyrings/aetherinox*gpg
#
#   as of 1.0.0.3-alpha, deprecated apt-key method removed for adding
#   gpg key. view readme for new instructions. registered repo now
#   contains two files
#       -   trusted gpg key:        aetherinox-proteus-apt-repo-archive.gpg
#       -   source .list:           /etc/apt/sources.list.d/aetherinox*list
#
#   ${1}    ReqTitle
#           contains a string if exists
#           triggers is function called from another function to check for
#               a prerequisite
##--------------------------------------------------------------------------

app_setup()
{

    clear

    local ReqTitle=${1}
    local bMissingAptmove=false
    local bMissingCurl=false
    local bMissingWget=false
    local bMissingGPG=false
    local bMissingRepo=false

    # require whiptail
    if ! [ -x "$(command -v apt-move)" ]; then
        bMissingAptmove=true
    fi

    # require curl
    if ! [ -x "$(command -v curl)" ]; then
        bMissingCurl=true
    fi

    # require wget
    if ! [ -x "$(command -v wget)" ]; then
        bMissingWget=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo gpg key
    #
    #   NOTE:   apt-key has been deprecated
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
    ##--------------------------------------------------------------------------

    if ! [ -f "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" ]; then
        bMissingGPG=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo .list
    ##--------------------------------------------------------------------------

    if ! [ -f "/etc/apt/sources.list.d/${app_repo_apt_pkg}.list" ]; then
        bMissingRepo=true
    fi

    # Check if contains title
    # If so, called from another function
    if [ -n "$ReqTitle" ]; then
        if [ "$bMissingAptmove" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            echo -e "[ ${STATUS_HALT} ]"
        fi
    else
        if [ "$bMissingAptmove" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            echo
            title "First Time Setup ..."
            echo
            sleep 1
        fi
    fi

    ##--------------------------------------------------------------------------
    #   missing whiptail
    ##--------------------------------------------------------------------------

    if [ "$bMissingAptmove" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Installing apt-move package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Adding apt-move package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install apt-move -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing curl
    ##--------------------------------------------------------------------------

    if [ "$bMissingCurl" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Installing curl package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Adding curl package" ""
        sleep 0.5
    
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install curl -y -qq >> /dev/null 2>&1
        fi
    
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing wget
    ##--------------------------------------------------------------------------

    if [ "$bMissingWget" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Installing wget package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Adding wget package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install wget -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing gpg
    ##--------------------------------------------------------------------------

    if [ "$bMissingGPG" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Adding ${app_repo_author} GPG key: [https://github.com/${app_repo_author}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Adding github.com/${app_repo_author}.gpg" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://github.com/${app_repo_author}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing proteus apt repo
    ##--------------------------------------------------------------------------

    if [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Registering ${app_repo_apt}" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-70s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Updating repo list" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   install app manager proteus file in /HOME/USER/bin/proteus
    ##--------------------------------------------------------------------------

    if ! [ -f "$app_file_proteus" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-70s %-5s\n" "${TIME}      Installing ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-70s %-5s' "    |--- Installing ${app_title}" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            mkdir -p "$app_dir_home"

            local branch_uri="${app_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   add env path /HOME/USER/bin/
    ##--------------------------------------------------------------------------

    envpath_add $HOME/bin

    if [ -n "$ReqTitle" ]; then
        title "Retry: ${1}"
    fi

    sleep 0.5

}
app_setup

##--------------------------------------------------------------------------
#   func > notify-send
#
#   because this script requires some actions as sudo, notify-send will not
#   work because it has no clue which user to send the notification to.
#
#   use this as a bypass to figure out what user is logged in.
#
#   could use zenity for this, but notifications are limited.
#
#   NOTE:   must be placed after func app_setup() otherwise notify-send
#           will not be detected as installed.
##--------------------------------------------------------------------------

notify-send()
{
    # func name
    fn_name=${FUNCNAME[0]}

    # get name of display in use
    local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

    # get user using display
    local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

    # detect id of user
    local uid=$(id -u $user)

    sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus $fn_name "$@"
}

##--------------------------------------------------------------------------
#   output some logging
##--------------------------------------------------------------------------

[ -n "${OPT_DEV_ENABLE}" ] && printf "%-70s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_ENABLE}" ] && printf "%-70s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ -n "${OPT_DEV_NULLRUN}" ] && printf "%-70s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_NULLRUN}" ] && printf "%-70s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

##--------------------------------------------------------------------------
#   list > packages
##--------------------------------------------------------------------------

lst_packages=(
    'mysql-server'
    'mysql-common'
    'mysql-client'
    'nginx'
    'nginx-core'
    'nginx-common'
    'nginx-doc'
    'nginx-confgen'
    'nginx-dev'
    'nginx-extras'
    'nginx-full'
    'nginx-light'
    'libnginx-mod-http-auth-pam'
    'libnginx-mod-http-cache-purge'
    'libnginx-mod-http-dav-ext'
    'libnginx-mod-http-echo'
    'libnginx-mod-http-fancyindex'
    'libnginx-mod-http-geoip'
    'libnginx-mod-http-headers-more-filter'
    'libnginx-mod-http-ndk'
    'libnginx-mod-http-perl'
    'libnginx-mod-http-subs-filter'
    'libnginx-mod-http-uploadprogress'
    'libnginx-mod-http-upstream-fair'
    'libnginx-mod-nchan'
    'libnginx-mod-rtmp'
    'libnginx-mod-stream-geoip'
    'dialog'
    'wget'
    'apt-move'
    'apt-utils'
    'gpg'
    'gpgv'
    'kgpg'
    'gpgconf'
    'keyutils'
    'adduser'
    'debconf'
    'lsb-base'
    'gnome-keyring'
    'gnome-keysign'
    'gnome-shell-extension-manager'
    'libc6'
    'network-manager-config-connectivity-ubuntu'
    'network-manager-dev'
    'network-manager-gnome'
    'network-manager-openvpn-gnome'
    'network-manager-openvpn'
    'network-manager-pptp-gnome'
    'network-manager-pptp'
    'network-manager'
    'networkd-dispatcher'
    'open-vm-tools-desktop'
    'open-vm-tools-dev'
    'open-vm-tools'
)

##--------------------------------------------------------------------------
#   list > architectures
##--------------------------------------------------------------------------

lst_arch=(
    'amd64'
    'arm64'
    'all'
)

##--------------------------------------------------------------------------
#   associated app urls
#
#   when certain apps are installed, we may want to open a browser window
#   so that the user can get a better understanding of where to find
#   resources for that app.
#
#   not all apps have to have a website, as that would get annoying.
##--------------------------------------------------------------------------

declare -A get_docs_uri
get_docs_uri=(
    ["$app_dialog"]='http://url.here'
)

##--------------------------------------------------------------------------
#   header
##--------------------------------------------------------------------------

show_header()
{
    clear

    sleep 0.3

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This is a package which handles the Proteus App Manager behind"
    echo -e "  the scene by grabbing from the list of registered packages"
    echo -e "  and adding them to the queue to be updated."
    echo

    if [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}APPS ${NORMAL}" "${BOLD}${FUCHSIA} ${app_i} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}DEV ${NORMAL}" "${BOLD}${FUCHSIA} $([ -n "${OPT_DEV_ENABLE}" ] && echo "Enabled" || echo "Disabled" ) ${NORMAL}"
        echo
    fi

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    printf "%-70s %-5s\n" "${TIME}      Successfully loaded ${app_i} packages" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-70s %-5s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null

    echo -e "  ${BOLD}${NORMAL}Waiting on selection ..." >&2
    echo
}

##--------------------------------------------------------------------------
#   Selection Menu
#
#   allow users to select the desired option manually.
#   this may not be fully integrated yet.
#
#   latest version
#       apt-get download --print-uris package | cut -d' ' -f1
#
#   specific version
#       apt-get download --print-uris package=version | cut -d' ' -f1
##--------------------------------------------------------------------------

app_start()
{

    show_header

    begin "Downloading Packages"
    echo

    IFS=$'\n' lst_pkgs_sorted=($(sort <<<"${lst_packages[*]}"))
    unset IFS

    mkdir -p "${app_dir_storage}/{all,amd64,arm64}"

    for i in "${!lst_pkgs_sorted[@]}"; do
        pkg=${lst_pkgs_sorted[$i]}

        for j in "${!lst_arch[@]}"; do
            #   returns arch
            #   amd64, arm64, i386, all
            arch=${lst_arch[$j]}
            
            #   package:arch
            local pkg_arch="$pkg:$arch"

            #   download "package:arch"
            apt download "$pkg_arch" >> $LOGS_FILE 2>&1

            #   http://us.archive.ubuntu.com/ubuntu/pool/universe/d/<package>/<package>_1.x.x-x_<arch>.deb
            #   app_url=$(sudo ./apt-url "$pkg_arch" | tail -n 1 )

            #   <package>_1.x.x-x_<arch>.deb
            app_filename=$(sudo ./apt-url "$pkg_arch" | head  -n 1 )

            if [[ -f "$app_dir/$app_filename" ]]; then
                if [[ "$arch" == "all" ]] && [[ $app_filename == *all.deb ]]; then
                    printf '%-70s %-5s' "    |--- Downloading $app_filename" ""
                    mv "$app_dir/$app_filename" "$app_dir_storage/all/"
                    echo -e "[ ${STATUS_OK} ]"
                elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb ]]; then
                    printf '%-70s %-5s' "    |--- Downloading $app_filename" ""
                    mv "$app_dir/$app_filename" "$app_dir_storage/amd64/"
                    echo -e "[ ${STATUS_OK} ]"
                elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb ]]; then
                    printf '%-70s %-5s' "    |--- Downloading $app_filename" ""
                    mv "$app_dir/$app_filename" "$app_dir_storage/arm64/"
                    echo -e "[ ${STATUS_OK} ]"
                else
                    rm "$app_dir/$app_filename"
                fi
            fi
        done

    done

    finish

}

app_start