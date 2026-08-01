Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 1800
  config.vm.communicator = "ssh"
  config.ssh.connect_timeout = 300 
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "cncf-lab1"

  config.vm.provider "virtualbox" do |vb|
    # vb.gui = true
    # vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.memory = "4096"
    vb.cpus = 2
  end

  config.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true

  config.vm.provision "shell", path: "scripts/01-install-tools.sh"
  config.vm.provision "shell", path: "scripts/02-setup-kind.sh", privileged: false
  config.vm.provision "shell", path: "scripts/03-deploy-cncf-stack.sh", privileged: false
end
