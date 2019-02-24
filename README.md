## ansible-discourse-demo
Discourse install and deployment on AWS using Ansible

1. Clone anisble-discourse-demo in your local machine.

2. Copy `one-click-install` script to your home directory and make sure it has executable permission on it.

3. Copy these three directories `creatingEC2`, `addingKeys/` and `runningScript/` from `anisble-discourse-demo` to `/etc/ansible/` directory.

4. Make necessary changes in `/etc/ansible/creatingEC2/group_vars/all` as per your requirement.

5. Create vault file named as `aws-keys.yml` inside `/etc/ansible/creatingEC2/vars_files/`.

6. Copy your exisiting ssh public key in `/etc/ansible/addingKeys/users/public_keys/<name_of_file>.pub`.

7. You should be having your own domain before starting installation. If you don't own one, purchase it.

8. Edit `/etc/ansible/runningScript/script/discourse_install.sh` file as per your requirement. For example. hostname, developer_emails, smtp_address, smtp_port, smtp_user_name, letsencrypt_account_email and smtp_password.

9. Make sure you have added `[discourse]` group in ansible's `hosts` file.

10. To get rid of ssh key authenticity warning, add below line in `tc/ansible/ansible.cfg`
```
[defaults]
host_key_checking = False
  ```
10. Run `one-click-install` script from your home directory.

11. Once `creatingEC2` playbook is completed, it'll copy list of nameservers provided by AWS in `/tmp/nameservers` file, copy those 4 nameservers and replace it in your hosting site from control panel.

12. Once script has successfully completed, it would print endpoint of your application.

### How it works

1. creatingEC2 : This playbook will install depenedent libraries, create security group, create hosted zone, copy the list of nameservers created by AWS in `/tmp/nameservers` file, Create an EC2 key for ssh, Save ssh key in `aws-private.pem` file, Create an EC2 instance, Allocating elastic IP to an instance, Copy elastic IP to a file for future use, add the newly created EC2 instance to host group, wait for SSH to come up, add a host to the ansible-playbook in-memory inventory, and add an A record in hosted zone with value as a elastic IP.

2. addingKeys : This playbook will upload ssh key to remote host.

3. runningScript : This playbook will copy main `discourse_install.sh` script to remote host.
