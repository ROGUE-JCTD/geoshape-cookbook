# -*- mode: ruby -*-
# vi: set ft=ruby :

public_address = "192.168.99.101"

Vagrant.configure('2') do |config|
  config.vm.define "geoshape" do |gs|    
    gs.omnibus.chef_version = '12.7.2'
    gs.vm.hostname = 'geoshape'

    gs.vm.box = 'bento/centos-7.2'
    gs.vm.provider 'virtualbox' do |v|
      v.memory = 3072
      v.cpus = 2
    end

    gs.vm.network :private_network, ip: public_address
    gs.berkshelf.berksfile_path = 'Berksfile'
    gs.berkshelf.enabled = true

    gs.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = 'cookbooks'
      chef.nodes_path = 'nodes'
      chef.run_list = [
        'recipe[geoshape]'
      ]

      chef.json = {
        "geoshape" => {
          "endpoint" => public_address
        }
      }
    end
  end
end
