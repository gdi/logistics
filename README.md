# LOGISTICS

## A Simple Configuration System

The goal here is to create something that is less complex than a chef-style system, and therefore also less bound by OS-dependencies and a central server with a ton of fiddly moving parts. The basics are all in place: you configure the specifics of your setup with a series of JSON files (by default in `config/`): packages.json, gems.json, deployment_orders.json, and servers.json.

You then write a bunch of *installation containers*, placing them by default in `warehouse/`. These are the guts of the system--principally, there's a config.json and an install.mustache file in there. Yes, you heard that right: the scripts are actually mustache templates. The config.json contains any information the delivery system will need to know and some template data for the installation script template. You can also upload files, other scripts, etc. and pretty much do anything that you can do with the shell. It's all SSH or mustache magic.

There's some more guidance about creating containers in their readme file. There is also a rake task: `rake warehouse:new_container`.

## How to

Get it in your capistrano/deployment scripting environment:

    require 'logistics'

Change the warehouse and/or config paths:

    Logistics.warehouse_path = "/path/to/containers"
    Logistics.config_path = "/path/to/configs"

Bootstrap an entire environment:

    logistics = Logistics::Logistikon.new "environment"
    logistics.inception!

Bootstrap a new server:

    manifest = Logistics::Manifest.for_server "the_server_name", "environment"
    Logistics::ShippingManager.deliver_from_manifest manifest

Install specific packages on a specific server:

    the_containers = container_names.map { |name| Logistics::ShippingContainer.new name }
    Logistics::DeliveryTruck.deliver_packages_to_server "the_server", *the_containers

Reconfigure (i.e. re-upload config files, but don't run the install script):

    sc = Logistics::ShippingContainer.new "package_name"
    d = Logistics::DeliveryTruck.new "the_server", sc
    d.reconfigure

## What is a Logistikon?

It's the central organizer. You can configure a set order of commands to be run with the `deployment_orders.json` file, in which you specify primary, secondary, and tertiary setup tasks that will bootstrap your environment for the rest of the process. This is, for instance, where you might install, configure, and launch a private gem server. The priority-based keys take `roles` and `servers` keys (which will be turned into a Manifest object), and also a `local` key, which points to a hash of strings with commands to be run on the local machine.

## What it Can't Do (yet)

It only knows how to help you configure services to run with daemontools/supervise. There is an abstract base class for service configuration called ServiceKit, but Supervise is the only implemented subclass at the moment... ideally, that would change. init isn't that hard (see the sample nginx configuration), and runit, monit, god, etc. would be nice to have.

It doesn't log... unless you consider stdout to be a log, and it doesn't redirect stdout from the scripts running remotely to your local terminal. This is possible and desirable--so that we could capture a complete transcript--so it's coming.

It doesn't have a server that it reports status to. One of the nice things about chef is that--if all goes well--you can log on to your chef-server web UI and see when the last time you ran recipes against a given server. I'd like to extend this so that you could hit up a server and see which containers (and checksums) were installed when and optionally view the installation log, on a per-container basis. That would be fairly bad-ass. If you could click-to-install packages or roles, all the better.

It doesn't have the ability to say "hey, this machine already has X" and skip container X, i.e. it cannot do partial or incremental configuration. It's all or nothing. I think we could manage this by checksumming the container and interacting with the aforementioned server to see if we've delivered that container already.

## tl;dr

There are examples in the `examples/` directory.