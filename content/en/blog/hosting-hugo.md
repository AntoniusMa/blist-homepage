---
author: "Antonius Malsam"
title: "Hosting your HUGO Website on Ubuntu with Apache"
description: "A guide on how to build and serve a HUGO Website with Ubuntu, Apache and Docker"
tags: ["docker", "HUGO", "apache", "container"]
date: 2023-10-31
thumbnail: https://miro.medium.com/v2/resize:fit:704/1*QPeS1zcQMRH_bvZgESgCIg.png
---

# Introduction

Welcome to the third and final part of my blog series about creating my personal homepage. After I showed you how to create a HUGO website using the [blist-theme](https://github.com/apvarun/blist-hugo-theme) and how to add a personal resume using the [hugo-mod-json-resume](https://github.com/schnerring/hugo-mod-json-resume) plugin, let's take a look at how to publish our website to the world. This time all you need to get started with the tutorial is any buildable HUGO website, the project and theme specifics of this tutorial are minimal.

# Prerequisites

-    Access to personal web server with public IP (Ubuntu 22.04.3 LTS used in this post)
-    Docker installation
-    Your own domain name

# Building your website

If you have a HUGO website, that builds in development mode (`hugo server`), it is very easy to generate a build that can be served by any web server. Just go to the root directory of your project and run
```sh
hugo
```

This will build all the dependencies, layouts, css and scripts of your project and put them together in the `{$projectRoot}/public` directory. Later on I will show you, how to host this public directory with an Apache web server. For now, I want to create a Docker build, that will abstract the build process of our application, so that it can be built on any system that runs Docker, not just on our development machine. Therefore create a `Containerfile` in the root directory of your project and copy this:

```dockerfile
FROM docker.io/library/golang:1.21.3-bookworm
COPY . .
RUN apt-get update -y
RUN apt-get install wget git npm -y
RUN npm i -g postcss-cli
RUN npm i  
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.115.4/hugo_extended_0.115.4_Linux-64bit.tar.gz && \
    tar -xvzf hugo_extended_0.115.4_Linux-64bit.tar.gz  && \
    chmod +x hugo && \
    mv hugo /usr/local/bin/hugo && \
    rm hugo_extended_0.115.4_Linux-64bit.tar.gz
RUN hugo
VOLUME [ "/public" ]
```

This is not a traditional Docker file that creates a runnable image of our application for us. Instead, we will create the aforementioned public folder and expose it as a volume. Later on we can extract the public folder from that volume, but first let's take a look at the Containerfile. We'll use an Ubuntu golang image, because go is needed to build the website with HUGO. Then we copy the contents of our project directory into the build container. We update the packages and install wget, git and npm. Next we install npm dependencies and postcss-cli, which is a project specific for the blist-theme. We download the HUGO executable and start the build. We make sure to exclude everything from our projects directory that does not need to be copied into the Docker build. To do this, create a file named .dockerignore and add:

```.dockerignore
.gitignore
.gitmodules
build_and_deploy.sh
public
resources/_gen
node_modules
```

Now we can build our image with
```sh
docker build -t hugo-release -f Containerfile .
```
Specify a destination directory where you want to store the result of the build
```sh
export target_directory="/path/to/your/target"
```
After that, we can extract the public directory from the image with
```sh
docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
```

Let's break down the shell command. `docker run` will run our newly built image, the `--rm` flag will remove the container when we're done. `hugo-release` is the identifier tag of our build, with the command `tar -cv - public` we tell Docker to tar our public directory, and write it to the standard output. With `|` we pipe this output directly to tar again. This will extract the public directory back to our previously defined `$target_directory`. With `--strip-components=1` we tell tar to remove the leading directory component, meaning that the contents of the public directory will be copied, not the directory itself. Now we have a fully functional build of our website in the `$target_directory`.

# Configuring the web server

## Install Apache2 web server

To host our website on the Internet, we need a web server, preferably with a static public IP. The following instructions will show you, how to set up an Apache web server on an Ubuntu machine and host the HUGO website. If you've just recently purchased or provisioned the server, you will probably get a username and password for ssh connection to your server. I recommend replacing this method with your personal ssh key and disabling password authentication for ssh. You can find many tutorials on how to do this on the Internet, or just ask a tool like ChatGPT. This way of accessing your server is much more secure, as only you as the owner of your personal private key will have access. I would also recommend, adding another user with sudo privileges so that you're not always operating as the root user. This will give you another layour of security and safety since you'll have to verify sudo commands with a password and you'll be less likely to change or delete critical operation system parameters or files. Additionally make sure, that your domain points to your server's IP.

Now, without further ado let's start with deploying our website. You'll need docker and git already installed on your web server. Install the Apache web server with
```sh
sudo apt-get install apache2 apache2-doc apache2-utils
```

Check if your apache2 system service is running with:
```sh
systemctl status apache2
```

another way to verify that the server is running is to enter your IP address in a web browser. You'll see the Apache2 default page:
{{< figure src="/blog/hosting/apache-default.png" class="blog-figure-center shadow" >}}

For now we'll disable the default page and continue with configuring the firewall
```
sudo a2dissite 000-default.conf
systemctl reload apache2
```

## Configure firewall

For security reasons, it's recommended to use a firewall on your machine. Ubuntu comes with a built in firewall and many application do already have a configuration for it. To see, which applications can be configured automatically by Ubuntu's firewall run
```sh
sudo ufw app list
# Output:
# Available applications:
#   Apache
#   Apache Full
#   Apache Secure
#   OpenSSH
```

We will allow Apache Full. **Also don't forget to allow OpenSSH, if you don't, you will lose your ssh connection to the server. This is crucial, because if your server administrator does not provide any other way to connect to the server, you will be locked out of the system**

```sh
sudo ufw allow 'Apache Full'
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

the status command will show you your newly set firewall rules, which should look something like this:
```
Status: active

To                         Action      From
--                         ------      ----
Apache Full                ALLOW       Anywhere                  
OpenSSH                    ALLOW       Anywhere                  
Apache Full (v6)           ALLOW       Anywhere (v6)             
OpenSSH (v6)               ALLOW       Anywhere (v6)  
```

## Hosting your website

Now we'll prepare Apache to serve our site:
```sh
cd /var/www/html
sudo mkdir $your_domain_name
cd $your_domain_name
sudo mkdir public_html
sudo mkdir log
sudo mkdir backups
```

We've navigated to Apache's default location for html files, created a directory with the name of our domain and inside of the domain's directory we've created directories `public_html`, `log`, and `backups`. Now navigate to the location of our web server configurations and create a new configuration for our domain.

```sh
cd /etc/apache2/sites-available/
sudo vim $your_domain_name.conf
```

Inside this file add the following configuration and replace my domain with yours:
```conf
<VirtualHost *:80>
  # Admin email, Server Name (domain name), and any aliases
  ServerAdmin antonius.malsam@amcloudsolutions.de
  ServerName amcloudsolutions.de
  ServerAlias www.amcloudsolutions.de

  # Index file and Document Root (where the public files are lcoated)
  DirectoryIndex index.html index.php
  DocumentRoot /var/www/html/amcloudsolutions.de/public_html

  LogLevel warn
  ErrorLog /var/www/html/amcloudsolutions.de/log/error.log
  CustomLog /var/www/html/amcloudsolutions.de/log/access.log combined
</VirtualHost>
```

Save everything and enable the website

```sh
sudo a2ensite amcloudtech.de.conf
sudo systemctl reload apache2
```

When you enter your domain in your browser, you will see a basic index page showing the contents of your public_html directory.

{{< figure src="/blog/hosting/basic-index.png" class="blog-figure-center shadow" >}}

If you add the contents of your previously built HUGO public directory, the website will be displayed. If you don't want to copy it manually, keep following the blog post, we'll write a script for that.

## Enable ssl

At the moment our site is not secure, fortunately we can secure it with https quite easily. Our certificates are issued by [Let's Encrypt](https://letsencrypt.org/de/). We can secure the Apache web server with *Certbot*, a programm, that is used for requesting and renewing the Certificates that we use. Check out this blog post on [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-20-04) if you want to know more. I'll just give a quick setup guide.

First install *Certbot*
```sh
sudo apt-get install certbot python3-certbot-apache
```

Then run the following command, accept the terms and conditions and provide your personal information such as your e-mail address. You can use the default value for all the other prompts.

```sh
sudo certbot --apache
```

Accept the terms and conditions and provide your personal information such as your e-mail address. You can use the default value for all the other prompts. That's it our certificate is automatically issued and applied by using *Certbot*. To verify that it is automatically renewed, check

```sh
sudo systemctl status certbot.timer
```

## Automize release

Now that our web server is up and running and we can securely access it using our domain name, let's bring our website to the internet. As mentioned before, you could simply copy the result of the HUGO build to the `/var/www/html/$your_domain_name/public_html` directory. However doing this every time you want to update your site is very cumbersome, especially if you're changing the content a lot, as is the case with a blog. So let's automate the update process with a script.

The script should run our previously defined docker build and automatically copy the *public* directory inside the docker image to apache's *public_html* directory. Check out the code for the complete script on my [github](https://github.com/AntoniusMa/blist-homepage/blob/main/build_and_deploy.sh). We'll create it step by step right now. Create a file `build_and_deploy.sh` and add the following at the top:

```sh
#!/bin/sh

# Default value for target_directory
target_directory="./public"
```

This sets the shell type of this script to sh and adds a default value for the `$target_directory`. A public folder like the one created by HUGO is used on many different web servers to serve static web pages, so we cannot hardcode the path to our Apache-specific public_html directory. Instead we want to make this directory configurable by using a command line parameter. So the first part of our shell script will do just that:

```sh
while [ $# -gt 0 ]; do
    case "$1" in
        --target-directory | -t)
            shift
            target_directory="$1"
            ;;
        --help | -h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --target-directory, -t  Specify the target directory"
            echo "  --help, -h              Display this help message"
            exit 0
            ;;
        *)
            # Unknown flag
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done
```

The while loop iterates through each command line argument, where `$#` is the number of command line arguments. The `shift ` operation shifts the command line arguments to the left, effectively removing the first argument stored at `$1` and making the next one `$1`, while decreasing `$#`. The loop will run as long as there still are arguments left to process. In case it encounters an unknow option, the script will exit and in case the target-directory flag is set, it will overwrite the `target_directory` variable.

Next we will ask the user, if they really want to delete the contents of the `target_directory`. This is a security addition, since the Apache folders are protected, we'll need to run the script with root privileges, meaning we could delete any folder on the machine. An incorrect --target-directory variable should not result in data loss, or even worse the deletion of system files, so we add the following snippet:

```sh
# Prompt the user for confirmation
printf "This will delete the content of '$target_directory'. \n do you want to proceed? (y/n): "
read response

case "$response" in
    [yY])
        echo "Proceeding..."
        ;;
    [nN])
        echo "Build aborted."
        exit 0
        ;;
    *)
        echo "Invalid input. Aborting."
        exit 1
        ;;
esac
```

Now let's add the docker build
```sh
if sudo docker build -t hugo-release -f Containerfile .; then
    # create target directory if not exist
    mkdir -p $target_directory
    # clear target directory
    rm -r $target_directory/*
    # copy build to target directory
    sudo docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
else
    echo "Docker build failed, aborting..."
fi
```

We want to make sure that the docker build is successful, before we delete the old contents of the `target_directory`. After the Docker build, we'll empty the `target_directory` and copy the contents of the public directory using the command we introduced earlier. Make the script executable, add the script and the Containerfile to your git repository, push your changes and clone the repository to your server. Then all you have to do is to deploy your website is:

```sh
sudo -E ./build_and_deploy.sh --target-directory /var/www/html/amcloudsolutions.de/public_html/
```

The Containerfile and the build_and_deploy.sh script allow us to update the site by simply pulling from our repository and running a one-line command.


# Conclusion

In this post we've seen how to build and deploy a HUGO website. We've worked out a way to make the build independent of a development machine by using Docker, and we've automated the deployment by using a simple shell script. We've also seen how to configure an Apache web server to host a HUGO website and how to automatically obtain certificates for the web server using *Let's encrypt* and *Certbot*. And we've finally published the website we've been working on in the last few posts. This concludes my guide to creating my website with HUGO.

**HUGO Website Series**
-    [Create HUGO Website](https://amcloudsolutions.de/en/blog/hugo-website/)
-    [Resume Page for HUGO Website](https://amcloudsolutions.de/en/blog/cv-article/)
-    ⚪ [Hosting HUGO Website](https://amcloudsolutions.de/en/blog/hosting-hugo/)