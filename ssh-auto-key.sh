#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 hostname [hostname-shortcut] [remote-username]"
    echo "  hostname          : Network accessible host to connect to"
    echo "  hostname-shortcut : Optional short name for the host (defaults to hostname)"
    echo "  remote-username   : Optional username for remote host (defaults to current user)"
    exit 1
}

# Check if hostname is provided
if [ $# -lt 1 ]; then
    usage
fi

HOSTNAME="$1"
HOSTNAME_SHORTCUT="${2:-$HOSTNAME}"
REMOTE_USERNAME="${3:-$USER}"

# Use shortcut name for file naming, replacing dots with underscores
SAFE_NAME=$(echo "$HOSTNAME_SHORTCUT" | tr '.' '_')

# Create necessary directories
mkdir -p "$HOME/.ssh/keys.d"
mkdir -p "$HOME/.ssh/conf.d"
chmod 700 "$HOME/.ssh"
chmod 700 "$HOME/.ssh/keys.d"
chmod 700 "$HOME/.ssh/conf.d"

echo "Adding $HOSTNAME to known_hosts..."
# Add host key to known_hosts
if ! ssh-keyscan -H "$HOSTNAME" >> "$HOME/.ssh/known_hosts" 2>/dev/null; then
    echo "Error: Failed to get host key for $HOSTNAME"
    exit 1
fi

echo "Creating SSH key pair for $HOSTNAME..."
# Generate SSH key
KEY_PATH="$HOME/.ssh/keys.d/id_ed25519_$SAFE_NAME"
if ! ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$USER@$(hostname)-to-$HOSTNAME" -q; then
    echo "Error: Failed to generate SSH key"
    exit 1
fi
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

echo "Copying SSH key to $HOSTNAME..."
# Copy the key to remote host
REMOTE_HOST="${REMOTE_USERNAME}@${HOSTNAME}"
if ! ssh-copy-id -i "$KEY_PATH.pub" "$REMOTE_HOST"; then
    echo "Error: Failed to copy SSH key to $HOSTNAME"
    exit 1
fi

echo "Creating SSH config for $HOSTNAME_SHORTCUT..."
# Create SSH config file
CONFIG_PATH="$HOME/.ssh/conf.d/$SAFE_NAME.conf"
cat > "$CONFIG_PATH" << EOF
Host $HOSTNAME_SHORTCUT
    HostName $HOSTNAME
    User $REMOTE_USERNAME
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF

# Add include to main SSH config if not already there
INCLUDE_LINE="Include conf.d/*.conf"
SSH_CONFIG="$HOME/.ssh/config"

# Create config file if it doesn't exist
touch "$SSH_CONFIG"

if ! grep -q "$INCLUDE_LINE" "$SSH_CONFIG"; then
    echo -e "\n$INCLUDE_LINE" >> "$SSH_CONFIG"
    echo "Added include directive to SSH config"
fi

echo "Testing SSH connection to $HOSTNAME_SHORTCUT..."
# Test the connection
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOSTNAME_SHORTCUT" "echo 'Connection successful'"; then
    echo "✓ Setup complete! You can now connect using: ssh $HOSTNAME_SHORTCUT"
else
    echo "✗ Connection test failed. Please check your configuration."
    exit 1
fi

exit 0