---
layout: post
title: "Dev-ops from 0 to Heroku"
date: 2013-09-23 16:26
published: false

---

Vagrant Specific (this is for your local box)

```
# add a new box, precise64 (12.04) is the latest Ubuntu LTS.
vagrant box add precise64 https://files.vagrantup.com/precise64.box

vagrant box list
```

Setting up the environment (on your vagrant/production box)
Goals -

- Bootstrap vagrant instance with Berkshelf
-  Install git, ruby, bundler, nginx
-  Get the static site out
Machine Setup

We will make use of Berkshelf to manage cookbooks. More info here:

```
# Berkshelf is pretty much bundler but for cookbooks
gem install berkshelf

# This plugin allows berkshelf to provision your vagrant box using the vagrant commands
vagrant plugin install vagrant-berkshelf

# The vagrant-omnibus plugin hooks into Vagrant and allows you to specify the version of the Chef Omnibus package you want installed using the omnibus.chef_version key
vagrant plugin install vagrant-omnibus
```

After the plugins are installed, create your cookbook using:

```
# Create the cookbook skeleton
berks cookbook nilenso-cookbook

# Bundle your Gemfile
bundle

# Lock down the ruby version
rbenv local 2.0.0-p247
```

The Vagrant file that got generated needs to be edited. Remove the legacy `config.ssh.timeout` and `config.ssh.maxtries` and add `config.vm.boot_timeout` setting as it is deprecated in Vagrant 1.3.0. Berkshelf (ver 2.0.10) has not yet been updated to reflect this in the scaffold that it generates. Since precise64 is already installed, you can get rid of the `box_url` setting and keep the `box` setting as `precise64`. `chef.json` can be omitted too. Keep the `chef_version` setting as `latest` so that omnibus will pick up the latest chef version while provisioning the box

```
Vagrant.configure("2") do |config|
  config.vm.hostname = "nilenso-cookbook-berkshelf"
  config.vm.box = "precise64"
  config.vm.network :private_network, ip: "33.33.33.10"

  config.omnibus.chef_version = :latest
  config.vm.boot_timeout = 120

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.run_list = [
        "recipe[nilenso-cookbook::default]"
    ]
  end
end
```

Time to get the box up and running.

```
vagrant up
```

If everything went well, we can check if chef was installed on the box by sshing into it.

```
> vagrant ssh

> chef-client -v
Chef: 11.6.0
```

It's time to create a user and a group on the new box that we've created.

```
group "nilenso"

user "deploy" do
  group "nilenso"
  system true
  shell "/bin/bash"
end
```

NOTE: Mention refactoring out attributes

Let's ssh into the box and check if the user and group got added.

```
> id deploy
uid=998(deploy) gid=1003(nilenso) groups=1003(nilenso)
```
Now that the user and group is set up properly, let's move on to install nginx.

### Installing nginx

We begin by adding `nginx` into in the `metadata.rb`.

```
depends "nginx", "~> 1.8.0"
```

Now that the dependency is stated we should invoke it from our `default` recipe. It is best to update the package manager cache depending on the linux flavour you're using. In our case, since we're using Ubuntu, we include the `apt` recipe so that it can update the package list and provide us with the latest `nginx-1.8.0`.

NOTE: Figure out how to make this distribution agnostic.

Ensure that the `apt` recipe is included before `nginx` as chef installs packages in the specified order.

```
include_recipe 'apt'
include_recipe 'nginx'
```

The following code mirrors a basic nginx setup. You can check out the attributes used in the cookbook [README](https://github.com/opscode-cookbooks/nginx).

```
nginx_site 'default' do
  enable false
end

directory "/var/www/nilenso" do
  action :create
  recursive true
end

template "#{node[:nginx][:dir]}/sites-available/nilenso" do
  source "nilenso.erb"
  mode 0777
  owner node[:nilenso][:user]
  group node[:nilenso][:group]
end

nginx_site "nilenso" do
  enable true
end

cookbook_file "/var/www/nilenso/index.html" do
  source "index.html"
  mode 0755
  owner node[:nilenso][:user]
end
```

NOTE: Explain the dsl

The `cookbook_file` section creates the `index.html` file in the `/var/www/nilenso` directory.
The `template` section creates the nginx configuration file from the erb template situated at `template/default/nilenso.erb`

```
server {
  server_name <%= node['hostname'] %>;

  location / {
    root /var/www/nilenso;
    index index.html index.htm;
  }
}
```

Create an index file at `files/default/index.html` which would eventually serve as the index file for the website as mentioned in the configuration file.  

NOTE: Refactor out custom attributes

### Installing Ruby

Next we'll setup `rbenv` and then instruct it to install `ruby` and `bundler` for us. We'll start by adding this dependency in `metadata.rb` first.

```
depends "rbenv", "~> 1.6.5"
```

And then simply writing another recipe file like before called `ruby.rb`.

```
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

rbenv_ruby "2.0.0-p247" do
  global true
end

rbenv_gem "bundler" do
  ruby_version "2.0.0-p247"
end
```
Include it in `default.rb` as `include_recipe "nilenso-cookbook::ruby"`
