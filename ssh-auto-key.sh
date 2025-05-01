#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 hostname [hostname-shortcut] [remote-username]"
    echo "  hostname           - Network accessible host (required)"
    echo "  hostname-shortcut  - Shortcut name for SSH config (optional)"
    echo "  remote-username    - Username on remote host (optional)"
    exit 1
}

# Check if hostname is provided
if [ $# -lt 1 ]; then
    echo "Error: Hostname is required"
    usage
fi

# Assign parameters
HOSTNAME="$1"
SHORTCUT="${2:-$HOSTNAME}"
REMOTE_USER="${3:-$(whoami)}"

# Create .ssh directory if it doesn't exist
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Create SSH config directory if it doesn't exist
mkdir -p "$HOME/.ssh/conf.d"
chmod 700 "$HOME/.ssh/conf.d"

echo "Generating SSH key pair for $HOSTNAME..."
# Generate SSH key without passphrase
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_${HOSTNAME}" -N "" -C "Generated for $HOSTNAME on $(date +'%Y-%m-%d')"

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSH key"
    exit 1
fi

echo "Copying SSH key to $REMOTE_USER@$HOSTNAME..."
# Copy the public key to the remote host
ssh-copy-id -i "$HOME/.ssh/id_${HOSTNAME}.pub" "${REMOTE_USER}@${HOSTNAME}"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy SSH key to remote host"
    exit 1
fi

# Create SSH config file for this host
CONFIG_FILE="$HOME/.ssh/conf.d/${SHORTCUT}.conf"
echo "Creating SSH config file at $CONFIG_FILE..."

cat > "$CONFIG_FILE" << EOF
Host $SHORTCUT
    HostName $HOSTNAME
    User $REMOTE_USER
    IdentityFile $HOME/.ssh/id_${HOSTNAME}
    IdentitiesOnly yes
EOF

# Check if Include directive is already in main config
if [ ! -f "$HOME/.ssh/config" ] || ! grep -q "Include conf.d/\*.conf" "$HOME/.ssh/config"; then
    echo "Adding Include directive to main SSH config..."
    # Create or append to SSH config
    echo -e "Include conf.d/*.conf\n" >> "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

echo "Testing SSH connection to $SHORTCUT..."
# Test the connection
TEST_OUTPUT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$SHORTCUT" "echo 'SSH connection successful'" 2>&1)
TEST_RESULT=$?

if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ Success! SSH connection to $SHORTCUT ($REMOTE_USER@$HOSTNAME) is working."
    echo "You can now connect using: ssh $SHORTCUT"
else
    echo "❌ Failed to connect to $SHORTCUT ($REMOTE_USER@$HOSTNAME)."
    echo "Error: $TEST_OUTPUT"
    echo "Please check your network connection and try again."
    exit 1
fi

exit 0