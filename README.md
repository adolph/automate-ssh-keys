# automate-ssh-keys

Goal: make ssh keys easier to generate and push

Prompt:

```
Bash script
required parameter hostname that is a network accessible host
optional parameter hostname-shortcut
optional parameter remote-username
Order of operations
ssh-keyscan hostname and append output to .ssh/known_hosts
exit if ssh-keyscan fails
create if it doesn't exist directory .ssh/keys.d/ and .ssh/conf.d/
create a ssh keypair with no passphrase named for the hostname in the .ssh/keys.d/ directory
ssh-copy-id the new keypair to the host using the current user or remote-username
if this process fails, exit the script
create a new ssh conf named for the host in .ssh/conf.d/
append an ssh conf include statement including the new ssh conf
test by running a ssh command on the remote host and echo to the user success or failure
```

Test: be able to locally test the above script

Prompt:

```
Bash script
setup, run and cleanup a user-space sshd that can receive a test ssh connections from user "test-user" and password "test-password"
keep all config in the local directory
```
