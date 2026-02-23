#!/usr/bin/env bash
set -euo pipefail

# Standardize variables with braces per Trunk audit
OS_TYPE="$(uname -s)"
APT_UPDATED=0

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

apt_update_once() {
    if [[ "${APT_UPDATED}" -eq 0 ]]; then
        sudo apt-get update -qq -y
        APT_UPDATED=1
    fi
}

install_package() {
    local pkg="$1"
    case "${OS_TYPE}" in
    Darwin)
        if ! command -v brew >/dev/null 2>&1; then
            echo "Install Homebrew first"
            exit 1
        fi
        # Braces and quoting pkg ensures safe execution
        brew list --versions "${pkg}" >/dev/null 2>&1 || brew install "${pkg}"
        ;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then
            apt_update_once
            sudo NEEDRESTART_MODE=a apt-get install -y -qq "${pkg}"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y -qq "${pkg}"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y -q "${pkg}"
        else
            echo "Unsupported Linux package manager. Install ${pkg} manually."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: ${OS_TYPE}. Install ${pkg} manually."
        exit 1
        ;;
    esac
}

install_hashicorp_tool() {
    local tool="$1"
    if ! command -v "${tool}" >/dev/null 2>&1; then
        if [[ "${OS_TYPE}" == "Darwin" ]]; then
            brew tap hashicorp/tap >/dev/null 2>&1 || true
            brew install "hashicorp/tap/${tool}"
        elif [[ "${OS_TYPE}" == "Linux" ]]; then
            ensure_hashicorp_repo
            apt_update_once
            install_package "${tool}"
        fi
    fi
}

ensure_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    command -v "${cmd}" >/dev/null 2>&1 || install_package "${pkg}"
}

# ------------------------------------------------------------
# AWS CLI + Config
# ------------------------------------------------------------

AWS_CONFIG="${HOME}/.aws/config"
if [[ ! -f "${AWS_CONFIG}" ]]; then
    mkdir -p "${HOME}/.aws"
    cat >"${AWS_CONFIG}" <<'EOF'
[default]
region = us-east-1
output = json

[profile prom_infradmin]
region = us-east-1
output = json
EOF
fi

# ------------------------------------------------------------
# Session Manager Plugin
# ------------------------------------------------------------

if ! command -v session-manager-plugin >/dev/null 2>&1; then
    ARCH="$(uname -m)"
    case "${OS_TYPE}-${ARCH}" in
    Darwin-*) brew install --cask session-manager-plugin ;;
    Linux-x86_64 | Linux-amd64) URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" ;;
    Linux-aarch64 | Linux-arm64) URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" ;;
    *)
        echo "Unsupported OS/arch: ${OS_TYPE}-${ARCH}"
        exit 1
        ;;
    esac
    if [[ -z "${URL-}" ]]; then
        echo "No download URL for Session Manager Plugin on this architecture."
    else
        curl -fsSL "${URL}" -o /tmp/session-manager-plugin.deb
        sudo dpkg -i /tmp/session-manager-plugin.deb || sudo apt-get -f install -y
        rm -f /tmp/session-manager-plugin.deb
    fi
fi

# ------------------------------------------------------------
# Special installers
# ------------------------------------------------------------

ensure_awscli() {
    if ! command -v aws >/dev/null 2>&1; then
        if [[ "${OS_TYPE}" == "Darwin" ]]; then
            brew install --cask aws
        elif [[ "${OS_TYPE}" == "Linux" ]]; then
            # Check architecture for AWS CLI Zip
            local arch_zip="x86_64"
            [[ "$(uname -m)" == "aarch64" ]] && arch_zip="aarch64"
            curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch_zip}.zip" -o "/tmp/awscliv2.zip"
            unzip -q /tmp/awscliv2.zip -d /tmp
            sudo /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
        fi
    fi
}

ensure_hashicorp_repo() {
    if [[ "${OS_TYPE}" == "Linux" ]] && [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
        wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor |
            sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
            sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    fi
}

ensure_kubectl() {
    if ! command -v kubectl >/dev/null 2>&1; then
        if [[ "${OS_TYPE}" == "Darwin" ]]; then
            brew install kubectl
        elif [[ "${OS_TYPE}" == "Linux" ]]; then
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key |
                sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" |
                sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
            sudo apt-get update -qq -y
            sudo apt-get install -y -qq kubectl
        fi
    fi
}

# ------------------------------------------------------------
# Tool Installs
# ------------------------------------------------------------

ensure_kubectl
ensure_awscli
ensure_command make
ensure_command jq
install_hashicorp_tool terraform
install_hashicorp_tool vault