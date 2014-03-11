# Project Occam

[![Build Status](https://jenkins.puppetlabs.com/job/occam-acceptance-matrix/badge/icon)

## Introduction

Project Occam is a power control, provisioning, and management application
designed to deploy both bare-metal and virtual computer resources. Occam
provides broker plugins for integration with third party such as Puppet.

This is a 0.x release, so the CLI and API is still in flux and may
change. Make sure you __read the release notes before upgrading__

Project Occam is versioned with [semantic versioning][semver], and we follow
the precepts of that document.  Right now that means that breaking changes are
permitted to both the API and internals, although we try to keep compatibility
as far as reasonably possible.


## How to Get Help

We really want Occam to be simple to contribute to, and to ensure that you can
get started quickly.  A big part of that is being available to help you figure
out the right way to solve a problem, and to make sure you get up to
speed quickly.

You can always reach out and ask for help:

* by email or through the web on the [puppet-occam@googlegroups.com][puppet-occam]
  mailing list.  (membership is required to post.)
* by IRC, through [#puppet-occam][irc] on [freenode][freenode].

If you want to help improve Occam directly we have a
[fairly detailed CONTRIBUTING guide in the repository][contrib] that you can
use to understand how code gets in to the system, how the project runs, and
how to make changes yourself.

We welcome contributions at all levels, including working strictly on our
documentation, tests, or code contributions.  We also welcome, and value,
input about your experiences with Project Occam, and provisioning in general,
on the mailing list as we discuss how the project should solve problems.


## Installation

* Razor Overview: [Nickapedia.com](http://nickapedia.com/2012/05/21/lex-parsimoniae-cloud-provisioning-with-a-razor)
* Razor Session from PuppetConf 2012: [Youtube](http://www.youtube.com/watch?v=cR1bOg0IU5U)

Follow wiki documentation for installation process:

https://github.com/csc/Occam/wiki/installation

## Project Committers

This is the official list of users with "committer" rights to the
Occam project.  [For details on what that means, see the CONTRIBUTING
guide in the repository][contrib]

* [Nicholas Weaver](https://github.com/lynxbat)
* [Tom McSweeney](https://github.com/tjmcs)
* [Nan Liu](https://github.com/nanliu)

If you can't figure out who to contact,
[Tom McSweeney](https://github.com/tjmcs) is the best first point of
contact for the project.  (Find me at Tom McSweeney <tjmcs@bendbroadband.com>)

This is a hand-maintained list, thanks to the limits of technology.
Please let [Tom McSweeney](https://github.com/tjmcs) know if you run
into any errors or omissions in that list.


## Occam MicroKernel
* The Occam MicroKernel project:
[https://github.com/csc/Occam-Microkernel](https://github.com/csc/Occam-Microkernel)
* The Occam MK images are officially available at:
[https://downloads.puppetlabs.com/occam/](https://downloads.puppetlabs.com/occam/)

## Environment Variables
* $OCCAM\_HOME: Occam installation root directory.
* $OCCAM\_RSPEC\_WEBPATH: _optional_ rspec HTML output path.
* $OCCAM\_LOG\_PATH: _optional_ Occam log directory (default: ${OCCAM_HOME}/log).
* $OCCAM\_LOG\_LEVEL: _optional_ Occam log output verbosity level:

        0 = Debug
        1 = Info
        2 = Warn
        3 = Error (default)
        4 = Fatal
        5 = Unknown

## Starting services

Start Occam API with:

    cd $OCCAM_HOME/bin
    ./occam_daemon.rb start

## License

Project Occam is distributed under the Apache 2.0 license.
See [the LICENSE file][license] for full details.

## Reference

* Occam Overview: [Nickapedia.com](http://nickapedia.com/2012/05/21/lex-parsimoniae-cloud-provisioning-with-a-occam)
* Puppet Labs Occam Module:[Puppetlabs.com](http://puppetlabs.com/blog/introducing-occam-a-next-generation-provisioning-solution/)


[puppet-occam]: https://groups.google.com/forum/?fromgroups#!forum/puppet-occam
[irc]:          https://webchat.freenode.net/?channels=puppet-occam
[freenode]:     http://freenode.net/
[contrib]:      https://github.com/csc/Occam/blob/master/CONTRIBUTING.md
[license]:      https://github.com/csc/Occam/blob/master/LICENSE
[semver]:       http://semver.org/
