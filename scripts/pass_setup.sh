#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Checking for GPG keys..."
if ! gpg --list-secret-keys | grep -q sec; then
  echo "⚠️  No GPG key found. Creating one..."
  gpg --batch --passphrase '' --quick-gen-key "$(whoami)@$(hostname)" rsa4096 default never
fi

GPG_KEY=$(gpg --list-secret-keys --with-colons | grep '^sec' | head -n1 | cut -d':' -f5)
echo "✅ GPG key found: $GPG_KEY"

echo "🔐 Initializing pass with GPG key..."
pass init "$GPG_KEY"

echo "🔐 Verifying 'pass' credential manager..."
if ! command -v pass &>/dev/null; then
  echo "❌ 'pass' is not installed. Please install it first: https://www.passwordstore.org/"
  exit 1
fi

# --- AWS CLI CONFIGURATION ---
echo "☁️  Checking for AWS CLI..."
if ! command -v aws &>/dev/null; then
  echo "📦 Installing AWS CLI..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install awscli
  elif [[ -x "$(command -v apt-get)" ]]; then
    sudo apt-get update && sudo apt-get install -y awscli
  else
    echo "❌ Unsupported OS. Install AWS CLI manually."
    exit 1
  fi
fi

echo "🔐 Authenticating with AWS CLI..."
aws configure

echo "💾 Extracting AWS credentials for pass..."
AWS_CREDS_FILE="$HOME/.aws/credentials"
if [[ -f "$AWS_CREDS_FILE" ]]; then
  pass insert -m aws/credentials <<EOF
$(cat "$AWS_CREDS_FILE")
EOF
  echo "✅ Stored AWS credentials in pass under 'aws/credentials'"
else
  echo "⚠️ AWS credentials file not found!"
fi

# --- DOCKER CONFIGURATION ---
echo "🐳 Checking Docker CLI..."
if ! command -v docker &>/dev/null; then
  echo "❌ Docker CLI not found. Please install Docker first."
  exit 1
fi

echo "🔐 Configuring Docker to use pass for credentials..."
mkdir -p ~/.docker
cat <<EOF > ~/.docker/config.json
{
  "credsStore": "pass"
}
EOF

echo "✅ Docker is now using pass as a credential store."

# --- GCP CLI CONFIGURATION ---
echo "☁️  Checking for gcloud CLI..."
if ! command -v gcloud &>/dev/null; then
  echo "📦 Installing gcloud..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install --cask google-cloud-sdk
  elif [[ -x "$(command -v apt-get)" ]]; then
    echo "Adding GCP SDK repo and installing..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
      sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
      sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
  else
    echo "❌ Please install gcloud manually: https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
fi

echo "🔐 Authenticating with GCP..."
gcloud auth login

echo "🔐 Authenticating Application Default Credentials (ADC)..."
gcloud auth application-default login

ADC_PATH="$HOME/.config/gcloud/application_default_credentials.json"
if [[ -f "$ADC_PATH" ]]; then
  pass insert -m gcp/adc <<EOF
$(cat "$ADC_PATH")
EOF
  echo "✅ Stored GCP ADC credentials in pass under 'gcp/adc'"
else
  echo "⚠️ GCP ADC credentials file not found!"
fi

echo "✅ All credential configurations complete!"
echo "👉 Run: aws-vault add <profile-name> to store AWS credentials securely."
echo "👉 Then: aws-vault exec <profile-name> -- <command>"
echo "👉 aws-vault exec my-profile -- aws s3 ls"
echo "👉 aws-vault exec my-profile -- terraform plan"
echo "👉 aws-vault exec my-profile -- docker build ."
