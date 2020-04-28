Documentation for Load-Balancer:

## Server Setup Instructions:
* [Setup Nginx](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04) for Ubuntu 18.04 on a new EC2 instance. *Supplementary step*: Add [Nginx](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/) PPA to run latest stable Nginx version, instead of the default OS Nginx, since it's not updated as frequently and can lag on some feature/security fixes.
* Setup LetsEncrypt according to [this](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04) guide on the server.
* The Elastic IP assigned to the load-balancer instance _must_ be: `54.172.90.245`.

## Server Administration:
* How to login to the Nginx Load-balancer server: 
	* Login to bastion server: `ssh aws-admin` (if you have the SSH config setup), or `ssh ec2-user@jump.dosomething.org`.
	* `ssh nginx-lb`. In case the `/etc/hosts` file is borked, you can also use `ssh 10.100.60.26`. 
* All Nginx server config files live in `/etc/nginx/conf.d` and take the filname format: `example-com.conf`.
* To check Nginx config: `sudo nginx -T`. 
* To Reload/Restart/Start/Stop/Status Nginx service: `sudo systemctl nginx reload/restart/start/stop/status` (associated command with mapped '/' separated command).

## How to setup a brand new domain for redirect:
* Copy-pasta the following entry, and replace `example.com`:
```
server {
    server_name example.com; # This line can contain multiple domain entries, e.g. example.com www.example.com
    return 302 https://www.newdomain.com; # If you want to pass on the URI, you can use the format: https://www.newdomain$request_uri
}
```
* Generate the server certificate using: `sudo certbot --nginx -d example.com`. You can pass additional `-d example2.com` flags to the cerbot command to generate a certificate per domain. 
* At the `certbot` prompt to re-direct all traffic from `http->https`, default to yes.
* Once the certificate is generated, run `sudo systemctl reload nginx`. 
* Finally test validity of certificate renewal via: `sudo certbot renew --dry-run`. 
* Test the redirect via `curl -Iv example.com` and look for the `302 redirect message`.

