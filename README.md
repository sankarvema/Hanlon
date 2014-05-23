# Project Hanlon

## Introduction

Project Hanlon is a power control, provisioning, and management application
designed to deploy both bare-metal and virtual computer resources. Hanlon
provides broker plugins for integration with third party such as Puppet.

Hanlon started its life as Razor so you may encounter links to original created-for-Razor content.  The following links, for example, provide a background info about the project:

* Razor Overview: [Nickapedia.com](http://nickapedia.com/2012/05/21/lex-parsimoniae-cloud-provisioning-with-a-razor)
* Razor Session from PuppetConf 2012: [Youtube](http://www.youtube.com/watch?v=cR1bOg0IU5U)

This is a 0.x release, so the CLI and API is still in flux and may
change. Make sure you __read the release notes before upgrading__

Project Hanlon is versioned with [semantic versioning][semver], and we follow
the precepts of that document.  Right now that means that breaking changes are
permitted to both the API and internals, although we try to keep compatibility
as far as reasonably possible.


## How to Get Help

We really want Hanlon to be simple to contribute to, and to ensure that you can
get started quickly.  A big part of that is being available to help you figure
out the right way to solve a problem, and to make sure you get up to
speed quickly.

You can always reach out and ask for help by email or through the web on the [hanlon-project@googlegroups.com][hanlon-project]
  mailing list.  (membership is required to post.)  
  
If you want to help improve Hanlon directly we have a
[fairly detailed CONTRIBUTING guide in the repository][contrib] that you can
use to understand how code gets in to the system, how the project runs, and
how to make changes yourself.

We welcome contributions at all levels, including working strictly on our
documentation, tests, or code contributions.  We also welcome, and value,
input about your experiences with Project Hanlon, and provisioning in general,
on the mailing list as we discuss how the project should solve problems.


## Installation  

Follow wiki documentation for [Installation Overview](https://github.com/csc/Hanlon/wiki/Installation-%28Overview%29)


## Project Committers

This is the official list of users with "committer" rights to the
Hanlon project.  [For details on what that means, see the CONTRIBUTING
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


## Hanlon MicroKernel
* The Hanlon MicroKernel project:
[https://github.com/csc/Hanlon-Microkernel](https://github.com/csc/Hanlon-Microkernel)
* The Razor images are officially available at:
[https://downloads.puppetlabs.com/razor/](https://downloads.puppetlabs.com/razor/)

## License

Project Hanlon is distributed under the Apache 2.0 license.
See [the LICENSE file][license] for full details.

## Reference

The following links contain useful information on the Hanlon (and Hanlon-Microkernel) projects as well as information on the new CSC Open Source Program:

* Tom McSweeney's blog entry on the availability of this project: [Announcing Hanlon and the Hanlon-Microkernel](http://osclouds.wordpress.com/?p=2)
* Dan Hushon's blog entry on the new CSC Open Source Program: [Finding Value in Open Source](www.vdatacloud.com/blogs/2014/05/14/finding-value-in-opensource)

This set of links, on the other hand, provide an introduction to the original Razor project (and, as such, may be of interest to those new to the Razor/Hanlon community):

* Razor Overview: [Nickapedia.com](http://nickapedia.com/2012/05/21/lex-parsimoniae-cloud-provisioning-with-a-razor)
* Nick Weaver's Razor Session from PuppetConf 2012: [Youtube](http://www.youtube.com/watch?v=cR1bOg0IU5U)

Finally, this link provides information on the Puppet Labs Module that was written to manage the deployment and configuration of Razor by Puppet.

* The Puppet Labs Razor Module:[Puppetlabs.com](http://puppetlabs.com/blog/introducing-razor-a-next-generation-provisioning-solution/)

Even though it doesn't support Hanlon, the information in that blog may provide useful to those who would like to develop a corresponding Hanlon module since the Hanlon is firmly rooted in the original Razor project.


[hanlon-project]: https://groups.google.com/d/forum/hanlon-project
[contrib]:      https://github.com/csc/Hanlon/blob/master/CONTRIBUTING.md
[license]:      https://github.com/csc/Hanlon/blob/master/LICENSE
[semver]:       http://semver.org/
