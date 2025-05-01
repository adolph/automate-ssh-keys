#!/bin/bash

# Script to set up, run, and clean up a user-space sshd for testing

# Exit on any error
set -e

# Directory for all SSH server files
SSHD_DIR="./sshd-test"
mkdir -p "$SSHD_DIR"
cd "$SSHD_DIR"

echo "Setting up test SSH server in $(pwd)..."

# Create subdirectories
mkdir -p etc
mkdir -p var/run
mkdir -p var/empty
mkdir -p home/test-user/.ssh

# Generate host keys
ssh-keygen -t rsa -f etc/ssh_host_rsa_key -N "" -q
ssh-keygen -t ecdsa -f etc/ssh_host_ecdsa_key -N "" -q
ssh-keygen -t ed25519 -f etc/ssh_host_ed25519_key -N "" -q

# Create sshd_config
cat > etc/sshd_config << EOF
# Test sshd configuration
Port 2222
Protocol 2
HostKey $(pwd)/etc/ssh_host_rsa_key
HostKey $(pwd)/etc/ssh_host_ecdsa_key
HostKey $(pwd)/etc/ssh_host_ed25519_key
AuthorizedKeysFile $(pwd)/home/test-user/.ssh/authorized_keys
UsePAM no
ChallengeResponseAuthentication no
PasswordAuthentication yes
PidFile $(pwd)/var/run/sshd.pid
PermitRootLogin no
StrictModes no
PrintMotd yes
PrintLastLog no
UsePrivilegeSeparation no
SubsystemSftp internal-sftp

# Simple test account setup
Match User test-user
    X11Forwarding no
    AllowTcpForwarding no
    AllowAgentForwarding no
    ForceCommand echo "Test SSH connection successful!"
EOF

# Create test user
echo "test-user:$(openssl passwd -1 "test-password")" > etc/passwd

# Set up cleanup function
cleanup() {
    echo "Cleaning up..."
    if [ -f var/run/sshd.pid ]; then
        PID=$(cat var/run/sshd.pid)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            echo "SSH server stopped"
        fi
    fi
    echo "Done!"
}

# Register cleanup on script exit
trap cleanup EXIT

# Start sshd
echo "Starting SSH server on port 2222..."
/usr/sbin/sshd -f $(pwd)/etc/sshd_config -D -e -h $(pwd)/etc/ssh_host_rsa_key -o "AuthorizedKeysFile=$(pwd)/home/test-user/.ssh/authorized_keys" &
SSHD_PID=$!
echo $SSHD_PID > var/run/sshd.pid

echo "SSH server is running with PID $SSHD_PID"
echo "You can connect using: ssh -p 2222 test-user@localhost"
echo "Password: test-password"
echo
echo "Press Ctrl+C to stop the server and clean up"

# Wait for sshd process to complete or user interrupt
wait $SSHD_PID