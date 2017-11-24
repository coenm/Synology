# Enable SSH in DSM
- Login into DSM as admin;
- Open 'Main Menu' and navigate to 'Terminal & SNMP';
- Check the 'Enable SSH service';
- Optionally change the SSH port.


# Firewall
In DSM, you should set the firewall to only allow incoming SSH connections for specific clients.
- allow specific external ip address
- allow internal ip range
- deny rest.



# SSH Keypair
For user Alice, we can generate a SSH keypair by

``
ssh-keygen -t rsa -b 4096 -C "alice@domain.com"
``

Set the location to: `/volume1/homes/alice/.ssh/id_rsa`


Do not enter a passphrase if Alice's private key is going to be used in an automated rsync script.


If the keypair generation is done as root, you need to set the owner to Alice: `chown -R alice:users /volume1/homes/alice/.ssh/`.

Also set the access permissions:

```
chmod 755 /volume1/homes/alice/.ssh
chmod 600 /volume1/homes/alice/.ssh/id_rsa
chmod 644 /volume1/homes/alice/.ssh/id_rsa.pub
```


# Improve SSH Daemon configuration
Login using SSH as root and verify/update the following settings:

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
I.e. for user `alice` you can `cat /etc/passwd | grep alice:` to check the users shell she has access to. If Alice should have access, his should be `/etc/sh`.

To update:
- `vi /etc/passwd`
- press `i`
- make changes
- press `Esc`
- press `ZZ`


# Todo
Check if reboot of sshd is required and if so, how to do this