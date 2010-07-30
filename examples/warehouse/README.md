# What is a warehouse?

It's where installation packages go, of course!

There is a specific form factor that the ShippingContainer requires, though:

    #{package_name}/
      config.json
      install.mustache
      files/
        # any auxiliary files you need go in here

## What goes in a config.json?

Well, it should be valid json, for starters. Secondly, the following keys have meaning:

 * `files` should point to an array of hashes where the key is the local filename (corresponding to a file in the `files/` dir), and the value is that file's final destination on the server.
 * `defaults` should point to a hash that the mustache templating system will make use of. These will be merged and overwritten by anything passed in to the container specifically.
 * if the package is a service that should be run by init.d/supervise, etc. then create a `service` key, pointing to somethin' like so: `{ "type": "supervise", "instances" => 4, "defaults" => {} }`. You'll also need to supply a `supervise.mustache` file which will get copied to the appropriate location and used to control the service.
 * if there are any scripts that you know will need to be run *last*, then create an `after_install` key pointing to an array of these script names. They're assumed to be `.mustache` files in the root directory.

That's it for now.

Here's a sample config.json with all the bells and whistles:

    {
      "defaults":{ "version": "5.0.47" },
      "files":[ { "my.cnf": "/etc/mysql/my.cnf" } ],
      "after_install": ["do_something"],
      "service": {
        "type": "supervise",
        "instances": 4,
        "defaults": {
          "start_at": 3400
        }
      }
    }

## What goes in an install.mustache?

This should be valid shell script, marked up in the mustache templating language. Variables are simply marked out by `{{double_braces}}`. The values in `config.json` and passed in to the `ShippingContainer` instance will be interpolated in as appropriate.

## What goes in the `files/` directory?

Any files that you've specified in the "files" section of config.json. These will be uploaded to the paths you specify on the server.

## More advanced things, how can I do them?

Well, there are a number of things that are upcoming, but in the meantime, we've found (rare) cases where we needed to do something that wasn't supported. Usually, you can work around this by a) writing a ruby script to do what you need, b) uploading it, and c) running it after_install.

## Configuring a service, how does it work?

Adding a top-level "service" key will let the delivery system know that you want to configure this software to run as a service. You'll need to at least tell it what "type" of service this is, which should correspond to a subclass of `ServiceKit::Kit`. You also need to either a) create a file `service_type_name`.mustache, or b) create a different file and tell the service config where it is. This file will be used as a template for the service's control script, e.g. it is a template init.d or supervise run file.

Known and utilized keys include:

 * `instances`: if there are going to be multiple instances of this software running, tell the delivery system how many here. Your service control script is responsible for managing them.
 * `start_at`: the starting port number for the service. Only used if a multi-instance service. See more below.
 * `defaults`: this hash is passed to Mustache when it renders the control script template.
 * `file`: if you didn't name your script template after the service type, use this key to tell the `ServiceTechnician` class where to find it.

One quick point: if you're writing the template for a multi-instance service, the template will have two additional variables in scope: `instance`, which is the number of the current index (1-indexed), and `port`, which is `start_at` + `instance`.
