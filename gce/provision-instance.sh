#!/usr/bin/env bash

# Exit on error - Equivalents are: '-e' and '-o errexit'
set -o errexit

# Fail on pipe failures
set -o pipefail

#
# Check for Root
#
if [[ $(id -u) -gt 0 ]]; then
    echo "ERROR: Script $0 must be run as root or with sudo root. Exiting."
    exit 1
fi

# Ubuntu Required Packages
os_ubuntu_prereq_package_list="apt-transport-https ca-certificates"

# CentOS Required Packages
os_centos_prereq_package_list=""

# Docker
docker_ubuntu_package_list="docker-engine ruby jq"
docker_centos_package_list="docker docker-compose"

# Docker Compose
docker_compose_version="1.9.0"
docker_compose_source_url="https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)"
docker_compose_install_dir="/usr/local/bin"
docker_compose_executable="${docker_compose_install_dir}/docker-compose"

# OS Version
os_dist_name="${1:-${OS_DIST_NAME:-NOT_SET}}"


detect_os() {

    local _python_platform_string

    if command -v python >/dev/null 2>&1; then
        _python_platform_string="$(python -c "import platform; print(platform.platform())")"
        _python_platform_string="$(echo "${_python_platform_string}" | tr 'A-Z' 'a-z')"

        case ${_python_platform_string} in

            *debian*)
                echo "debian"
                return 0
                ;;
            *ubuntu*)
                echo "ubuntu"
                return 0
                ;;
            *centos*)
                echo "centos"
                return 0
                ;;
            *redhat*)
                echo "redhat"
                return 0
                ;;
            *)
                echo "UNSUPPORTED_OS_${_python_platform_string}"
                return 1
                ;;
        esac
    else
        echo "PYTHON_NOT_FOUND"
        return 1
    fi
}


install_package_manager_prereqs() {
#
# Install any required supporting packages and keys for the OS package manager
#
    local _os_dist_name
    local _package_to_install

    if [[ -n ${1:-} ]]; then _os_dist_name="${1}"; else echo "ERROR-MISSING_PARAM_1_OS_DIST_NAME"; return 1; fi

    case ${_os_dist_name} in

        ubuntu|debian)
            if [[ -n ${os_ubuntu_prereq_package_list} ]]; then
                echo "INFO: Installing Ubuntu prerequisite packages..."
                for _package_to_install in ${os_ubuntu_prereq_package_list}
                do
                    echo "INFO:   ${_package_to_install}"
                done
                apt-get install -y ${os_ubuntu_prereq_package_list}
            else
                echo "INFO: Ubuntu prerequisite package list is empty; nothing to install."
            fi

            echo "INFO: Adding Docker GPG key for apt repo ..."
            apt-key adv \
                --keyserver hkp://ha.pool.sks-keyservers.net:80 \
                --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
            echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list

            echo "INFO: Running apt-get update ..."
            apt-get update
            ;;

        centos|redhat)
            echo "ERROR-UNSUPPORTED_OS_VERSION"
            return 1
            ;;

        *)
            echo "ERROR-UNSUPPORTED_OS_VERSION"
            return 1
            ;;

    esac

}


install_packages() {
#
# Install Packages
#
    local _os_dist_name
    local _packages_to_install
    local _package_to_install

    if [[ -n ${1:-} ]]; then _os_dist_name="${1}"; else echo "ERROR-MISSING_PARAM_1_OS_DIST_NAME"; return 1; fi
    if [[ -n ${2:-} ]]; then _packages_to_install="${2}"; else echo "ERROR-MISSING_PARAM_2_PACKAGES_TO_INSTALL"; return 1; fi

    case ${_os_dist_name} in

        ubuntu|debian)
            echo "INFO: Installing the following packages ..."
            for _package_to_install in ${_packages_to_install}
            do
                echo "INFO:   ${_package_to_install}"
            done

            # Install the packages
            apt-get install -y --allow-unauthenticated ${_packages_to_install}
            ;;

        centos|redhat)
            echo "ERROR-UNSUPPORTED_OS_VERSION"
            return 1
            ;;

        *)
            echo "ERROR-UNSUPPORTED_OS_VERSION"
            return 1
            ;;

    esac

}


install_docker-compose() {

    local _docker_compose_installed_version
    local _install_docker_compose

    echo "INFO: Checking for docker-compose version ${docker_compose_version} ..."

    if [[ -x ${docker_compose_executable} ]]; then
        echo "INFO: ${docker_compose_executable} exists and is executable. Checking version..."
        _docker_compose_installed_version="$("${docker_compose_executable}" version | grep docker-compose | grep version | awk '{ print $3 }' | tr -d ',')"
        if [[ ${_docker_compose_installed_version} == "${docker_compose_version}" ]]; then
            _install_docker_compose="no"
        else
            _install_docker_compose="yes"
        fi
    else
        _install_docker_compose="yes"
    fi

    if [[ ${_install_docker_compose} == "yes" ]]; then
        echo "INFO: Installing docker-compose version ${docker_compose_version} ..."
        echo "INFO: Source: ${docker_compose_source_url}"
        echo "INFO: Destination: ${docker_compose_executable}"
        curl -L "${docker_compose_source_url}" -o "${docker_compose_executable}"
        chmod +x "${docker_compose_executable}"
        return 0
    else
        echo "INFO: docker-compose version ${_docker_compose_installed_version} exists, and matches specified version."
        return 0
    fi
}


## Execute

# Check to see if os_dist_name is set
if [[ -z ${os_dist_name} || ${os_dist_name} == "NOT_SET" ]]; then
    echo "WARN-MISSING_SCRIPT_PARAM_3_OR_ENV_VAR_NOT_SET_OS_DIST_NAME"
    echo "Attempting to determine OS dist name..."
    os_dist_name="$(detect_os)"
fi

case ${os_dist_name} in

    *ubuntu*)
        install_package_manager_prereqs "ubuntu"

        if [[ -n ${docker_ubuntu_package_list} ]]; then
            install_packages "ubuntu" "${docker_ubuntu_package_list}"
        fi

        if ! sudo systemctl is-active docker --quiet; then
            systemctl start docker
        fi
        ;;

    *centos*)
        install_package_manager_prereqs "centos"

        if [[ -n ${docker_centos_package_list} ]]; then
            install_packages "centos" "${docker_centos_package_list}"
        fi

        if ! sudo systemctl is-active docker --quiet; then
            systemctl start docker
        fi
        ;;

    *)
        echo "ERROR-UNSUPPORTED_OS_DIST_NAME_FOR_PACKAGE_INSTALLATION"
        exit 1
        ;;
esac
install_docker-compose
