# Overview

These are the tests used to validate OpenBSD KVM images before being released to images.joyent.com and the Joyent Public Cloud and images.joyent.com.

These tests are are based on [Serverspec](http://serverspec.org).

## Installation and Setup

To run the tests you will need ruby (1.9.3+ or 2.0.0 should work) and rubygems installed.

Install serverspec and dependencies with [bundler](http://bundler.io)

    bundle install

Copy the `properties_example.yml` file to `properties.yml`

Modify `properties.yml` with the name and properties you want to test.

Next, edit your `~/.ssh/config` file with the host information of the virtual machines you want to test. The name you chose for _Host_ in `~/.ssh/config` should match what you have in `properties.yml`.

For example, here's a `properties.yml` file:

    openbsd-6:
      :roles:
        - openbsd
      :name: OpenBSD 6.1
      :base_version: 20170520
      :doc_url: https://docs.joyent.com/images/kvm/openbsd

And an example `~/.ssh/config` file:

    openbsd-6:
      HostName XX.X.XXX.XXX
      User root

## Running the tests

To run the tests, run the following command (within this directory):

    rake serverspec

Or just:

    rake

More information on how to create Serverspec tests can be found here:

http://serverspec.org/tutorial.html

There's a list of useful Resource Types here that you can use for testing:

http://serverspec.org/resource_types.html
