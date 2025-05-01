# automate-ssh-keys
Goal: make ssh keys easier to generate and push
Prompt:
```
Bash script with required parameter hostname that is a network accessible host, and optional parameter hostname-shortcut and optional parameter remote-username
create a ssh keypair with no passphrase named for the hostname
ssh-copy-id the new keypair to the host using the current user or remote-username
create a new ssh conf named for the host
append an ssh conf include statement including the new ssh conf
test by running a ssh command on the remote host and echo to the user success or failure
```
