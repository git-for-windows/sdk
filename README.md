# Introduction

This is the [Git for Windows SDK](https://github.com/git-for-windows/sdk), provided by an Inno Setup based wrapper around [MinGW](http://www.mingw.org/)'s [mingw-get](http://sourceforge.net/projects/mingw/files/Installer/mingw-get/) which installs a development environment for building Git for Windows using GCC.

The Git executable being built is a native Windows application, it is not an MSYS (or Cygwin) application that uses a Unix emulation layer. Only the shell environment and some tools Git depends on are provided by MSYS. This is also the case for the [msysgit](https://github.com/msysgit/msysgit/) project, but as it contains "msys" in its name this has always been a source of confusion.

# Features

The installer strives to supersede the existing msysgit netinstall package with some improvements that hopefully make the life of both Git for Windows developers and users much easier. In particluar, the improvements include:

* **Real installer:** Comes with an Inno Setup based installer with uninstall capabilities instead of just a self-extracting archive.

* **Package management:** All required packages are installed via MinGW's new [mingw-get](http://sourceforge.net/projects/mingw/files/Installer/mingw-get/) tool. This means that the installed packages can be updated independently of updates to the SDK installer, and in turn that there is no need to create a new SDK installer just because of updates to packages. You have full access to all upstream MinGW / MSYS packages in addition to custom packages provided by the Git for Windows SDK to improve the Git experience on Windows.

* **Execution of batch files:** You can execute _*.bat_ / _*.cmd_ files right away without manually prefixing them with _cmd.exe_.

# Download

Choose between the latest [release](https://github.com/git-for-windows/sdk/releases/latest) or the latest [snapshot](https://dscho.cloudapp.net/job/sdk-build-installer/lastSuccessfulBuild/artifact/download.html).

# Getting involved

## Setting up the environment

If you start from scratch without an existing MSYS environment (or Git client, for that matter) you have sort of a chicken-and-egg problem: In order to build the SDK installer or create mingw-get packages (see the [next section](#creating-mingw-get-packages)) you need various MSYS tools like curl or wget, sed, lzma, tar, unzip. The SDK installer provides those tools, but you do not have the installer yet. The easiest way to solve this is by downloading an already existing [snapshot release](https://dscho.cloudapp.net/job/sdk-build-installer/lastSuccessfulBuild/artifact/download.html) of the SDK installer, run it to set up the development environment, and use that environment to work on the SDK itself. To do so, select _Start the development environment_ on the installer's final page and type at the prompt:

    $ git clone https://github.com/git-for-windows/sdk.git git-for-windows-sdk # Clone the repository (or your fork of it)
    $ cd git-for-windows-sdk                                                   # Change to the working tree

**Then, start hacking on the SDK!** Everything in the _root_ directory goes as-is to the installation directory as created by the SDK installer. In particular, the [mgwport / msysport](http://gitorious.org/mgwport/mgwport/blobs/master/README) and catalogue / package description files for our custom MinGW / MSYS packages are in the _packages_ subdirectory. In case you would like to update one of the packages to a more recent version or create  new package, that is the place to go.

When you are done, building an up-to-date SDK installer is done by these steps:

    $ ./download-mingw-get.sh  # Download the most recent catalogue / package description files
    $ ./build-installer.sh     # Create the installer

If everything went fine you should now have a file matching _Git-SDK-*.exe_ which you can use to install the development environment including your changes.

## Creating mingw-get packages

Please see the separate [sdk-packages](https://github.com/git-for-windows/sdk-packages) repository for details.

## Getting in contact

We now have a [mailing list](https://groups.google.com/group/git-win-sdk) for developers.  Issues should be reported on the [git-for-windows/git tracker](https://github.com/git-for-windows/git/issues); mentioning "SDK" in the subject line is advisable.

# TODOs (roughly in order of priority)

* Upgrade Perl (to a version that includes [this patch](https://github.com/msysgit/msysgit/issues/61#issuecomment-10695361))
* Upgrade SVN libraries (requires new Perl)
* Create a new "Git for Windows" installer which also comes with mingw-get package management.
* Make `git help -a` work when built-ins are removed.
* Create a 64-bit version of "Git for Windows".
* Contribute [patches to MSYS](https://github.com/git-for-windows/sdk-packages/tree/master/msys-core) back upstream.
* Capture the console output of mingw-get and show the progress in the installer GUI.
