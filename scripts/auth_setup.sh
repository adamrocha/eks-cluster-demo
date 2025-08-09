#!/bin/bash

set -euo pipefail

# === CONFIGURE THIS ===
GPG_ID="<GPG key ID or email>"         # <-- CHANGE THIS to your GPG key ID or email
AWS_PROFILE_NAME="prom_infradmin"      # <-- CHANGE THIS to your desired AWS profile name

# === PRECHECKS ===
echo "🔍 Checking for Homebrew or APT..."
if command -v brew >/dev/null; then
  PKG_INSTALLER="brew install"
elif command -v apt-get >/dev/null; then
  sudo apt-get update
  PKG_INSTALLER="sudo apt-get install -y"
else
  echo "🛑 No supported package manager found (Homebrew or APT)"
  exit 1
fi

# === INSTALL pass ===
if ! command -v pass >/dev/null; then
  echo "🔧 Installing pass..."
  $PKG_INSTALLER pass
else
  echo "✅ pass already installed"
fi

# === CHECK GPG ===
if ! gpg --list-keys "$GPG_ID" >/dev/null 2>&1; then
  echo "🛑 GPG key '$GPG_ID' not found. Generate with: gpg --gen-key"
  exit 1
fi

# === INIT pass ===
if [ ! -d "$HOME/.password-store" ]; then
  echo "🔐 Initializing pass store with GPG key $GPG_ID"
  pass init "$GPG_ID"
else
  echo "✅ pass already initialized"
fi

# === INSTALL docker-credential-pass ===
if ! command -v docker-credential-pass >/dev/null; then
  echo "🐳 Installing docker-credential-pass..."
  $PKG_INSTALLER docker-credential-helper
else
  echo "✅ docker-credential-pass already installed"
fi

# === CONFIGURE Docker to use pass ===
echo "⚙️ Configuring Docker to use pass"
mkdir -p ~/.docker
cat > ~/.docker/config.json <<EOF
{
  "credsStore": "pass"
}
EOF

# === INSTALL aws-vault ===
if ! command -v aws-vault >/dev/null; then
  echo "🔐 Installing aws-vault..."
  $PKG_INSTALLER aws-vault
else
  echo "✅ aws-vault already installed"
fi

# === SETUP aws-vault PROFILE ===
if ! aws-vault list | grep -q "$AWS_PROFILE_NAME"; then
  echo "🔐 Setting up AWS Vault profile '$AWS_PROFILE_NAME'"
  aws-vault add "$AWS_PROFILE_NAME"
else
  echo "✅ AWS Vault profile '$AWS_PROFILE_NAME' already exists"
fi

# === DONE ===
echo "🎉 All tools installed and configured successfully!"

