# fpm-taskwarrior-server
Build [Taskwarrior][TW] server from a Makefile using [FPM][FPM]!

[TW]: https://taskwarrior.org/
[FPM]: https://github.com/jordansissel/fpm

Developed on Ubuntu, but should also support building on RedHat based systems as well.

## Prerequisites

### Ubuntu

~~~console
sudo apt install -y build-essential cmake git
sudo apt install -y python2.7 ruby-dev
sudo apt install -y uuid-dev libgnutls28-dev
sudo gem install fpm
~~~

### RedHat/CentOS

I don't use RedHat/CentOS. If you do, send me a PR to update the docs!

## Package Creation and Installation

As simple as:
~~~console
$ make
$ make install
~~~

Or to build the stable release for RedHat/CentOS:
~~~console
$ make VERSION=master PACKAGE_TYPE=rpm 
$ make install
~~~
