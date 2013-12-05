# puppet-ozone #

puppet-ozone is an [Ozone](https://www.owfgoss.org) build and configuration management module for Puppet.  Currently this module only supports RHEL6/CentOS6.x systems.

The public release of this module is intended only as a template for installing and setting up initial Ozone environments.  Using Puppet and this module for production environments is at your own risk.

## Using ##

Just add the following to your Puppet manifest:

	class { "ozone::ozone": }

## Vagrant

If you want to get a basic Ozone server running in a virtual machine, well that's real easy to do with Vagrant and Oracle VirtualBox (and this module).  Note, although I believe it's possible to get this to work on Windows I've never tried.  Take a look at the [Vagrant docs](http://docs.vagrantup.com/v1/docs/getting-started/index.html) for more info.

0.1 - The module has been updated to support the inclusion of a local
root CA to build the certificates against.  Drop the key and cert in the
files/ subdirectory and specify them on the class resource.

1. Download [VirtualBox](https://www.virtualbox.org/) and install
2. Ensure Ruby and Rubygems are installed `gem --version` (if not install)
3. Install the [Vagrant](http://www.vagrantup.com) gem `gem install vagrant`
4. Install a CentOS "box" locally: `vagrant box add CentOS6_64 https://dl.dropbox.com/u/7225008/Vagrant/CentOS-6.3-x86_64-minimal.box`
5. Create a new VM env: `mkdir MyBox && cd MyBox` then `vagrant init MyBox CentOS6_64`
6. Edit the newly created Vagrantfile and enable the Puppet config and the port to forward:

		config.vm.forward_port 443, 8443
		config.vm.forward_port 80, 8080
    
		config.vm.provision :puppet do |puppet|
    		puppet.manifests_path = "manifests"
    		puppet.manifest_file  = "mybox.pp"
    		puppet.module_path = "modules"
    		#puppet.options = "--verbose --debug"
  	end
    config.vm.network "private_network", ip: "192.168.10.20"

 7. Create the manifests and modules dirs: `mkdir manifests modules`
 8. Create the mybox.pp file in the manifests dir and fill 'er with:
 
		group { "puppet":
  			ensure => "present",
		}

		Exec {
  			path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
		}

	  class { "ozone::ozone": 
      ozone_https_port => "8443",
      ozone_hostname => "ozone",
      ozone_ca_cert => "henson.pem",
      ozone_ca_key => "henson.key"
    }	
9. Git clone this module into the modules dir: `cd modules; git clone https://bitbucket.org/codice/puppet-ozone.git ozone`
10. Now, you start the machine: `v up` from the MyBox directory

NOTE: Depending on resources available it may take a while.  For example, I've allocated a bit more RAM to box (in the Vagrantfile ) with : `config.vm.customize ["modifyvm", :id, "--memory", 2048]` and it still takes over an hour to complete the full provisioning.  Hey, we're building from source code here, and lots of good stuff comes out at the end.


When it's all said and done you should be able to see the running Ozone at [https://localhost:8443/owf](https://localhost:8443/owf) and login with testAdmin1:password.

If you have specified the root CA to the Puppet provisioning process,
you'll need to add the hostname to your local hosts file, pointing to
the appropriate IP address.

# Todo

# Problems?

Let me know at <kwplummer@radiantblue.com>
