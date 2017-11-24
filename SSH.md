# SSH Daemon configuration
Don't know why, but after a DSM update, the SSH settings are restored to default.

Check config for specific settings:
- Protocol2 should be enabled. `cat /etc/ssh/sshd_config | grep Protocol2`
- PubkeyAuthentication should be enabled. `cat /etc/ssh/sshd_config | grep PubkeyAuthentication`
- PasswordAuthentication should be disabled. `cat /etc/ssh/sshd_config | grep PasswordAuthentication `

To update:
- `vi /etc/ssh/sshd_config`
- press `i`
- make changes
- press `Esc`
- press `ZZ`

# User configuration
Specify the users that should be able to ssh to the nas. Check the `/etc/passwd` file.
Ie. for user `alice` you can `cat /etc/passwd | grep alice:` to check the users shell she has access to. For DSM, this should be `/etc/sh`.

To update:
- `vi /etc/passwd`
- press `i`
- make changes
- press `Esc`
- press `ZZ`


# Firewall
In DSM, you should set the firewall to only allow incoming SSH connections for specific clients.
- allow specific external ip address
- allow internal ip range
- deny rest.


## SSH Keypair
For user Alice, we can generate a SSH keypair by
``
ssh-keygen -t rsa -b 4096 -C "alice@domain.com"
``
Set the location to: `/volume1/homes/alice/.ssh/id_rsa`

Do not enter a passphrase if Alice's private key is going to be used in an automated rsync script.

## Todo
Check if reboot of sshd is required and if so, how to do this