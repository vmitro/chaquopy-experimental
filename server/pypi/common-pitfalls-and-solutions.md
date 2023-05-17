# Instead of an Introduction

## Who is this guide for?
This guide is aimed for Python developers creating apps for Android using Chaqopy as the Python backend, who want to build their own packages containing native code.

## What are the prerequisites for building Python packages containing native code?
Chaquopy (either official repo or this one), Python targets (available at https://repo.maven.apache.org/maven2/com/chaquo/python/target/), a compiler suite (C, C++, Fortran, Rust... etc.), a build system (GNU Make, Cmake, etc.) and a whole lotta nerves.

## Why is building native code so hard?
Normally Android apps were written in Java. The android SDK, a bunch of tools provided thrugh Google for this task, used the Java code to target their Virtual Machine (Dalvik). The Android self was and still is running on a Linux kernel. The kernel is just a part of the Operating System, it manages memory, file input/output, low level network communication and many other low level stuff. The Dalvik Virtual Machine runs on top of it and hosts Java compiled code. The compiled Java code interfaces different parts (usually the higher level stuff like Audio, Video, Internet, UI etc. Since pretty early, the Android apps could also in part other wholly be written in native code (usually C, C++) through leveraging the Android NDK (whereas SDK stands for software development kit, NDK means native development kit). 

The Android NDK had historically relied on GNU's Compiler Collection (GCC) as toolchain (a set of executables, libraries and header files for compiling, linking and postprocessing of executable code) for the task of translating C/C++ code into machine code that the CPU's in mobile phones, tablets etc. which ran Android understood; the CPU architecture of these embedded processors differed from your run-of-the-mill PC (Intel x86, AMD 64), they ran and still almost exclusivelly have ARM/ARM64 architecture. The two families of architecture differ greatly in the way the low level processing is organized, the register layout, the instruction set, memory I/O etc.

On the one hand, compiling native code is usually done by a compiler, a program running on a certain architecture, producing object files that are compatible with this very architecture. Those object files are then put together by a program named linker, also a program running on the same architecture, into either an executable file which can run on the native architecture, or a library (a shared object bzw. dynamic linked library) which can "lend" its routines and procedures other programs. This native architecture the compiler suite is runing on is usually called HOST architecture.

The compilers are just programs that produce other programs, they must either painstakingly be assembled in machine code (through careful planing the memory layout, memory management and other very low level stuff by hand, or better said, through usage of assembly language: instead of writing machine code directly one writes the CPU instructions for them and uses a program called assembler to translate instruction such as `MOV EBX, EAX` into the byte sequence `89C3` which when read by an Intel x86 processor would be interpreted and executed as `take the value from the EAX register and store it in the EBX register`. Pretty cool, eh? Also, very tedious.

A compiler is normally today built not from machine/assembly code, but from C/C++ code, or any code in a systems programming language (Rust). One could also write a fully functioning compiler in Python, but higher level and dynamic langugages are not very well suitable for the task bevcause of their speed. The way a compiler is built from say C code is through the process of bootstrapping; another C compiler is used to compile the source code which is minimally required to compile other levels or stages of compiler, then this newly compiled code is used to com,pile the next stage et cetera, usually there are three stages. The result is a collection of programs and libraries and header files that comprise a compiler toolchain, short: everything one needs to start writing programs in a language.

A compiler can be built from its source in such way, that although it **runs** on a certain architecture, it **produces** i.e. **compiles** executable code for **another** architecture. This sort of compiler is called a cross compiler and Android NDK is a cross compiler suite that runs on x86[_64] architecture (there are versions for Linux, MacOS and Windows), and produces executable code for Android on ARM, ARM64, x86, x86_64 architecture. Although the basic machine code instructions are the same for different operating systems, one can not directly execute Windows programs on a GNU/Linux system; the calling convention is different, the system organization is whole other world, etc. This organization is part of the system's ABI (application binary interface), which defines how data structures and functions that use them should behave. That's why you need a compatibility layer (e.g. WINE) to run Windows programs on GNU/Linux, and not an emulator: the most of the code internal to the program can execute without problems on the machine, but when the program wants to ask the OS kernel for some more memory, the way Windows and Linux handle this is very much different (from the POV of the user program at least).

## Can I compile stuff *directly* on my end device? Wouldn't that simplify the process greatly?
Yes, but just because you can, doesn't mean you should. There are a couple of ways how you could run **a** native code compiler (e.g. GCC, Clang) natively on an Android devide. Look into Termux, it's a completesolution with a terminal and a package manager, through which you could install the GCC toolchain or even Clang; from my experience, building stuff from source is possible, but not without caveats (e.g. when building a recent Vim binary on an old Fire HD 10 tablet running Android 5, only very old packages are available and the produced executable is buggy - when build as Debug it runs correctly, but the Release version cannot write files which is kinda big deal for a text editor).

Also, there is no official Android NDK for Termux. There is however a rather old version built through someone about 5 years before, so its quite possible that it is of no particular use.

And finally, Chaquopy's package build process (wheel building process) is developed and tested with GNU/Linux in mind so there is no guarantee that anything is going to work on Termux.

## Why are you writing all this, I don't need so much detail, I just wanna compile some libs, man!
I admit I am often (almost pathologically) overdescriptive, but I am also certain there are some people out there who want to know how stuff works on the inside. Also I think that, when one know *why* something happens, the explanation *how* makes much more sense. It could also inspire people to contribute back.

Also note the rather informal tone of these writings. It reflects the hacky-experimental nature of this fork and should always be interpreted with an opened spirit. It is however, to my best knowledge, also correct. Mainly because I sepnd very much of my free time trying to figure out how all this work (am basically only relatively fluent in Python). Suggestions, critique and hatemail belong to the Issues page.

## Can we talk about Python? You know, why we're here in the first place?
Most certainly, that's what the next section's for. But first, some more theory :)

# What's a package?

## Introduction
What happens when you issue a statment like `import thirdparty` into a Python interpreter? Or conversly, when you write this piece of code into a Python script? Well, what *should* happen is, the Python interpreter searches for a **file** (say `thirdparty.py`) or a module (a directory named `thirdparty` with an in most cases empty `__init__.py`) and loads some code from some file(s) in the computer memory and exposes them into the global namespace (but also packing it in a module object named `thirdparty`). That basically means you could use whatever top-level class or function it finds in the `.py` file or whatever classes/functions get explicitely exported by defining a `__all__` list in the init file with through end user importable objects.

But you already knew that, right? Many importable modules are a part of Python's standard library, meaning that they reside in **a** `site-packages` directory (more on that emphasized indefinite article later) usually bundled with the Python distribution itself. There are numerous modules that come together with Python that it's often said Python comes with "batteries included".

The default `site-packages` directory is sort of hard-coded, meaning that running Python without any arguments makes it populate its path search list with a preknown values (e.g. `/usr/local/lib/python3.10/site-packages`). 

## Installing a package
So all you need to do in order to install a package is copy its code into the default `site-packages` and call it a day? Just fire `pip install thirdparty` and stop worrying and love the bomb, right?

Well, not so fast. Faulty packages can and do sometimes break the default Python installation, essentially preventing your system from using Python to do its own important tasks. This is especially important on a GNU/Linux distribution, which could lead to a state where your operating system, well, stops being operative, and you need in simplest case a Python reinstall.

I mentioned earlier there's an object holding a list of paths where Python looks for modules. You can list these by doing an `import sys` and then `print(sys.path)`. It should look something like this:

```
$ python
Python 3.10.10 (main, Mar 21 2023, 18:45:11) [GCC 11.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import sys
>>> print(sys.path)
['', '/home/vmitro/miniconda3/envs/build-wheel/lib/python310.zip', '/home/vmitro/miniconda3/envs/build-wheel/lib/python3.10', '/home/vmitro/miniconda3/envs/build-wheel/lib/python3.10/lib-dynload', '/home/vmitro/.local/lib/python3.10/site-packages', '/home/vmitro/miniconda3/envs/build-wheel/lib/python3.10/site-packages']
>>>
```

You could also manipulate this list, add or remove paths from it at runtime. Say you have a neatly packaged bundle called `mypackage` which is just a directory with an `__init__.py`, which may contain one or more directories which also do contain it (e.g. `mypackage/largemodule/` with `usefulmath.py`, `someotherstuff.py` and `__init__.py`), and/or one or more Python files (say `modulette.py`). You could use something like `import sys; sys.path.append('mypackage'); import mypackage` to effortlessly use your package which resides in you source tree - just like any other module, but this approach is considered hacky and you should feel dirty if you ever decide to employ it.

## Virtual Environments
So, how *do* I install a package without messing up my global Python install? Well easy there, champ. That's (mainly) what virtual environments (short: venv) are for.

It turns out, if you copy the Python executable to a directory (say for example `myproject/venv/bin/`) and when we're at it, let's copy the pip exe into the same folder. Why not also make a `myproject/venv/lib` directory to hold our packages (we'll later add a `sys.path.append()` call at the beginning of every script, it should work, right?) Well it turns out there's alos an easier way, actually; let's just override the `PYTHONPATH` environment variable and skip the hack above! Now you can add, remove, modify and do all sorts of crazy stuff with the installed modules without worrying about breaking stuff. Very cool, indeed.

There are naturally software packages that handle all that hassle for you. They install a local copy of Python with the version you want, they handle environment variables, package management, and even come with a handy shell script that allows you to 'enter' this environment with a single command. When you 'activate' a previously prepared virtual environment, the activation script tells your shell that the python executable resides in a local path and sets other environment variables that all make it so as if Python environment is contained to this separate area of computer system. If you hava the desire to know more, an online search for `python virtual environment` should get you up to speed in no time.

## The Wheel Files
The invention of the wheel alowed mankind to progress at a untill then unfathomable pace. The invention of Python Wheels allowed Python programmers who wrote Python packages and libraries to distribute their bundled products at a greater speed than it was required before. Instead of distribution source files on a version control system, the package maintainers were able to distribute a completely built package as a single file (`.whl` files are normal `.zip` archives) with their relative directory structure resembling that of a standard Python distribution plus some more metadata; this way all the end user had to do is unzip it to their Python environment. Not even that, there are now tools that allow you to publish your package to a public repository for other people to download and use in their programs. Enter `pip`, the python package installer that can fetch Python Wheels from the Python Package Index repository and install it for you. It doesn't just do simple file extraction, it also keeps track of versions, dependencies, leverages setup scripts to actually build a wheel file from source, and many more useful things. Some repositories provide just the source code for a package and pip handles its compilation, build process and installation, while some others provide already packaged, compiled wheels for all kinds of Python environments, Operating Szstems and CPU architectures. For the end user, the interface between "I want this particular package" and "I can now use that package in my code" is a simple `pip install (...)` command. Or so it should be.

## Instead of a Conclusion
So in essence, to use a Python package in our Android app, we need to install a specific package, throughChaquopy using `pip` or some other means, that has its native code compiled for our desired architecture? In order to install it, we must either download it from somewhere, or we need to build a specific `.whl` file for our Android CPU architecture and then tell the Gradle build script that we're gonna install a package from file in the `pip {}` section of the `gradle.build` file, and only then can we use it in our Android app?

Yes.

Isn't this a lot of work?

Almost as much as writing this wall of text, so keep reading.

# Common Pitfalls and their Solutions

## 1. A `Chaquopy connot compile native code` pops up when I try to import a package on Android

If you read the wall of text above you'd likely have figured it out by yourself by now:

### The Why

Chaquopy **is** a native module in your that encompasses CPython, a Python interpreter **for Python code** on an Android device; Chaqopy **is not** a compiler for native code, meaning that you'll either have to compile and build this package yourself or wait for someone else to do it.

### The How

Since you're reading this, I reckon you are highly likely to want to do this yourself so keep on reading. Every compilation process is somewhat different so I'll try to explain the most common ones. 

## 2. I have no idea how to approach compiling stuff, please help!

### The Why

I assume you never needed to. Fear not, it's far less complicated than writing it in the first place!

### The How

If you recall from earlier (a couple of seconds ago), Chaquopy is no compiler so you're going to need to get one. Since Android is built ontop of Linux and Python is pretty much an important part of GNU/Linux and really, built around GNU/Linux you're gonna need a Linux. This guide assumes that you'll be using Ubuntu 22.04 LTS and all the shell commands and every build process is tried and tested on this GNU/Linux distribution. If you don;t have a spare computer to install it natively, and run a recent Windows 10/11 system, you can install Windows Subsystem for Linux 2 (WSL2) - it's basically a virtual machine that should work 1:1 like any Ubuntu system does natively. I won't go into details how to setup a WSL2 distribution, a simple online search query on any popular search engine should do (tip: `how to install wsl2` should provide you with all the required step within the first results page).

This guide also will not and cannot make you a Linux expert. But what it can do, is tell you the prerequuisites and specificalities of compiling native packages for Chaquopy for using them on an Android device. If you're using a Ubuntu system, you could already have known much of this info. If you're only just started for the first time "booting" a WSL2 GNU/Linux instance, follow on.

- The basic build stuff:

    Open up a terminal and install the essential build tools with the `sudo apt install build-essential cmake git autoconf automake libtool openjdk-18-jdk android-sdk sdkmanager`. This command installs the GNU Compiler Collection, GNU make, autotools and JDK (Java development kit) and Android SDK. I prefer this way of getting the Android SDK and NDK (through sdkmanager) to downloading and extracting the SDK/NDK in a user path bacause it features common install locatins which makes the level of customization of the build environment at a minimum. Oh, also we need [at least] Git to fetch sources.

- Android NDK:
    When you're at it, assuming the above commands were successful, install the Android NDK, which is a set of tools and compilers which can compile to native Android code on a GNU/Linux machine, by executing the `sudo sdkmanager 'ndk-bundle;r25c'`. Note the apostrophes (`'`) and the semicolon (`;`) - without them the command will likely fail. After the sdkmanager is done with installation you should have the NDK on your machine. Check the contents of the SDK directory with:

```
$ ls -ls /opt/android-sdk/
total 24
drwxr-xr-x  6 root root 4096 Apr  5 08:14 ./
drwxr-xr-x  3 root root 4096 Apr  1 11:07 ../
drwxr-xr-x  3 root root 4096 Apr 18 00:18 build-tools/
drwxr-xr-x  5 root root 4096 May  7 21:14 ndk/
drwxr-xr-x 11 root root 4096 Apr  5 08:14 ndk-bundle/
drwxr-xr-x  3 root root 4096 Apr  1 11:09 platforms/
```

You copy the first line **after** the dollar sign (`$`), the dollar sign should be your command prompt. To execute the command press ENTER. Don't worry if you don't have anython other than ndk-bundle.

Now test a compiler:
```
$ /opt/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi31-clang --version
Android (9352603, based on r450784d1) clang version 14.0.7 (https://android.googlesource.com/toolchain/llvm-project 4c603efb0cca074e9238af8b4106c30add4418f6)
Target: armv7a-unknown-linux-android31
Thread model: posix
InstalledDir: /opt/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin
```
Again, you should issue the command **after** the `$`. However, you should **not** just copy/paste the whole command. The path contains many directories and you can actually force the terminal/bash (the former is a program that allows you to write commands and see results, the latter a so called `shell`, a program that receives your commands, transforms and executes them and gives their output to the terminal to display) to autocomplete it for you. Here's how you do it. First, write `/opt` and press the TAB key. The prompt should now read `$ /opt/`. You can press the TAB key again to either display the contents of the `/opt/` directory if it contains more than one file/folder, or to automatically complete your prompt with the name of that one single file/folder inside it. On my machine, pressing TAB again makes the prompt read `$ /opt/android-sdk/` since it's the only directory inside opt (which btw stands for 'optional'). Now pressing TAB a couple of times brings this to my display:

```
$ /opt/android-sdk/
build-tools/ ndk/         ndk-bundle/  platforms/
```

You can see that bash listed the directories inside `/opt/android-sdk/`. Now I only need to add `ndk-` (note the slash) to my prompt and it gets automagically completed to `/opt/android-sdk/ndk_bundle/`. On your machine, it may very well be that you got to `.../ndk-bundle/` right after pressing the TAB key once. In order to get all the way to `.../linux-x86_64/bin` I just need to keep spamming TAB key occassionally adding the first few characters of the directory/file I want to execute and get what I want in no time (and most importantly, no brain processing time :)). When traversing GNU/Linux directory structure in bash, use TAB key as if it were the 'Right click on Desktop -> Refresh', the only difference being, on GNU/Linux it does someting other than helping your OCD/anxiety.

- You may need to configure Git in order to e.g. commit changes you made to a repo. See the [official GItHub docs](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address) for info how.

- Optionally, install Clang. If you ever needed to compile something for host that includes LLVM, you are going to need Clang. For example, building PyTorch requires a specific Protobuf version (the one that's installable through `apt` is older and not compatible with newest sources), you need a Clang compiler that can compile some part of LLVM (namely, the aformentioned libprotobuf with protoc compiler, and also sleef-native) first in order to compile the rest of the library. This process is called bootstrapping. You can get Clang by executing `sudo apt install clang-14`. Conviniently, this is the same major version (14) as the one supplied with r25c version of NDK.

- To be expanded.

## 3. I need a specific Python package which I want to use in my Chaquopy Android app. Can I simply copy *any* Wheel File I found on the internet?

No.

### The Why

For PC (or better said, X86_64 architecture, all 3 major Operating Systems, Linux, MacOS, Windows) there are pre-built wheel files, that are precompiled, prelinked, prepackaged. Thay also include compiled native code but in 99.9% of cases *NOT* for Android, i.e. not for Arm/Arm64 architecture, but for x86 (AKA 32-bit Intel) or more recently, x86_64 (sometimes called AMD 64-bit because Intel was a little slow at comming up with a solid 64-bit instructin set). Not only that, but also the ABI (short for application binary interface) differs between the Operating systems, architectures and even versions of the same OS/CPU architecture.  

I feel like here would be a good place for a pop-sci/nerd reference so here we go: using a wrong wheel file would be like trying to install DeLorean's flux capacitor into the Millenium Falcon. There, I said it. Yes, I feel bad about it.

### The How

Why, you build it yuorself, of course. See next entry.

## 4. Where do I begin with building a Python wheel file to use in my Chaquopy Android app?

### The Why

If a package isn't already built by the official Chaquopy distribution, your first step into building it would be to either clone the official Chaquopy repository, or this one. I like to have a top-level directory in my home folder where I keep all the projects' sources, I usually name it `~/projects/` or `~/install/`. I'm gonna use `projects` for this one, you can name it whatever you like, just remember to substitute your global source directory's name with the one you used to create it.

### The How

To make a projects directory in your home directory, you can either execute `$ mkdir -p ~/projects` or if you want to do it step by step:

```
$ cd
$ mkdir -p projects
```

THe first command, `cd` without any parameters, changes the current working dir to your home dir, the second creates a directory named `projects` inside the current working directory.

Instead of `~` which in terminal/shell stands for your home directory, for me, it's `/home/vmitro`. You can usually also use `$HOME` environment variable. Just make sure that you don't overwrite it because that can mess up the normal shell functioning in a great way. So either the two already stated commands, or `$ mkdir -p $HOME/projects` should work. Now to change your current working directory, execute `$ cd ~/projects`. This `-p` is just a switch, you can forget about it for now.

The command to clone this repository would be `$ git clone https://github.com/vmitro/chaquopy-cp310-android31.git`. This will fetch all the filesm from the repository with all my changes to it onto your hard drive. Give it a bit of time and if successful, go into the `chaquopy-(...)/server/pypi` directory. You use the `cd` command you used earlier, and then TAB-spam your way into it, e.g. I'm pretty certain that `~/projects$ cd chaq [TAB] ser [TAB] [TAB] [ENTER]` should result in following prompt: `~/projects/chaquopy-cp310-android31/server/pypi$`. Command line is magic, ain't it? Now execute `$ ls -ls packages` to see what kinds of packages come with Chaquopy. You can add `(...) | less` to the command (so it should read `$ ls -ls packages | less`) to "pipe" the output of the ls command into another program, less, which can display massive quantities of text one terminal page at a time. Use ENTER or SPACE or ARROW KEYS to move around, display more text, use `/` to search, i.e. `/torch [ENTER]`, ESCAPE doesn't exit but a single `[q]` does the trick. 

Now before we even *think* of building wheels, we need to do a final couple of steps.

Step one: get the appropriate Python targets.

On the [Chaquopy's central Maven repo](https://repo.maven.apache.org/maven2/com/chaquo/python/target/) navigate to the version of Python we want to build against (this version should match the one in `gradle.build` file but **NOT** the `buildPython` variable) - this guide assumes a relative newisht (May 2023) Python 3.10.WHATEVER. This whatever can be, well, watever because 3 is the MAJOR version number and 10 is the MINOR version number, the third number is reserved for non-compatibility breaking changes, meaning that everything that works with Python 3.10.`N` should also work with Python 3.10.`N+M`. Without further ado, in the [Python 3.10.x target directory's page](https://repo.maven.apache.org/maven2/com/chaquo/python/target/3.10.6-1/) download the `.zip` file for the architecture you want your Android app to build for. E.g. if in your `build.gradle` file under architectures stands `"x86"`, you download the [target-3.10.6-1-x86.zip](https://repo.maven.apache.org/maven2/com/chaquo/python/target/3.10.6-1/target-3.10.6-1-x86_64.zip) file.

Now, simply clicking this in your browser would probably download it into your Downloads folder, moving the file from there into appropriate directory would be to much hassle. You can use the `wget` command line program to download it directly into the `maven` directory. If you don't have it installed, typing wget without parameters should greet you with `bash: wget: command not found`. You can install it with `sudo apt install wget curl`. You are most certainly also going to need curl, another command line program which can download stuff from the internets and more (e.g. send POST/GET requests) so we're installing it here as well. If you followed this far, you are in the `(...)server/pypi` directory (you can see the current working directory on the command prompt, before the dollar sign). To change the active directory, we need to issue the `cd` command again. The `maven` directory resides in the Chaquopy's root directory, so you can use what you've used before to get there (basically, name the full path to it), but you can also use the `..` shortcut. The `..` in terminal terms stands for parent directory. Executing `cd ..` (note the whitespace! this ain't MS DOS) should take you to `(...)/server/` and executing the same command again in the Chaquopy's root directory. You can also type `cd ../..` to go two parent directories back. You could even chain a whole bunch of `..`'s like so `$ cd ../../server/../server/pypi/../..` and still end up at the same place. If you're uncertain where you are or what directories or files are in the current working dir, simply execute `$ ls -ls` to print the active directory's content, or `$ pwd` to print the full path of the currently active (working) dir. Now you should be in `~/projects/chaquopy-(...)/` and we need to enter the `maven` directory so do it with the `cd` command. Once inside, we need to make a whole bunch of nested dirs. That's where we write `$ mkdir -p com/chaquo/python/3.10.6-1`. We can then `cd com[TAB][TAB][TAB][ENTER]` or way into the newly created directory tree and finally, download our target zip. If you copied the link location on the maven's web page from earlier, you can now execute `$ wget https://path.to/the/zip.file.zip`. Note: CTRL+V may not work in your terminal, since the key combination is used to send special characters to it (this predates the internet, perhaps alos the copy/paste functionality). Alternativelly you can use SHIFT+INSERT key combination, or right click paste.

Step two: we certainly want to make certain our system's Python distribution remains pure. The easiest way is to install Miniconda. It's a Python distribution which comes with its own package manager and can manage virtual environments without even having to be installed into your system (it uses user space installation where the needed files are installed in your home directory). 

On its [download page](https://docs.conda.io/en/latest/miniconda.html#linux-installers) select the appropriate version for your system (Ubuntu 22.04 LTS users: you should have 3.10 already installed system-wide, so just select this one for Linux 64bit; this works in WSL2 too). Once downloaded (protip: use wget like we used before to have it automatically in your `~/projects` directory), we need to install it. Assuming we're now in `projects`, execute Miniconda's install script. Like so: `$ bash Miniconda3-latest-Linux-x86_64.sh`. Normally you can execute a script like so: `~/projects$ ./Miniconda3-latest-Linux-x86_64.sh` but here we are explicitelly spawning a new shell instance (because of this: [tl;dr](https://github.com/conda/conda/issues/10431)). You should then be prompted if you want to run `conda init` which we want so type `yes` and press ENTER. Follow the instructions on screen. If all goes well, you now have Miniconda installed on your machine. Either exit the terminal or source the appropriate file like it says on the last line (this you can freely copy/paste because you are only going to need to do it once). Now your prompt should change to `(base) ~/projects$` or wherever you were before. Now we can create a separate environment just for the purposes of building Chaquopy wheels! The command for that is `conda create -n build-wheel python=3.10`. If you're building for Chaqopy Python 3.9, you need to substitute the minor version from 10 to 9. Likewise for Python 3.11. For this guide, it's 3.10. This guide also targets the minimal Android API level of 31; there is no particular reason for that, it's just a need to use relatively newer instances of all files and packages plus 3.10 has almost all the same digits as API 31, so it's more aesthetic.

Now you have a working environment named `build-wheel` but you are using the `base` environment. To change it, execute `$ conda activate build-wheel`. To deactivate it and 'go into' your system's default Python environment, type `$ conda deactivate` until the prompt has no `(base) (...)` prefix. There's one final step to do, and that is to install the requirements for the `build-wheel.py` script; this script is provided by Chaquopy by default and automates the process of building custom Chaquopy Python packages, from getting the source code to producing the `.whl` file and everything in-between. The list of required packages is written in the file `requirements.txt` which should resides in (in case you followed this guide to the letter) in `~/projects/chaquopy-cp310-android31/server/pypi/`. Once you get there (hint: **c**hange **d**irectory should do the trick), install it by executing `(build-wheel) ~/projects/chaquopy-cp310-android31/server/pypi$ python -m pip install -r requirements.txt`.

## 5. I found a package that I want to build. The source is available as [`.tar.gz` | git repo | I wrote it myself]. How do I go from that to a `.whl` file?

First you need to take a look at the package because that determines the build process. It is described through `meta.yaml` and optionally `build.sh` and `*.patch` files. We'll cover each one of those but before we go and write those files, we need to know what kind of package is.

Some Python and Chaquopy packages depend on a system library. It's a `.so` or shared object file that doesn't get executed independently, but other programs can interface it and use it's code to do stuff or mangle data. Normally, these `.so` files reside in a `/usr/lib` directory or similar where your program can find them. Behind the curtains, the `ld-linux` program on GNU/Linux does this for you. Alternativelly, some libraries come as so-called *static* libriaries. When you build other libraries or applications that link to a library statically, during the linking process these these static libraries get appended to and incorporated into the final library/executable. In any case, the program or library getting linked must have access to these libraries in order to produce the end executable.

For example, PyTorch library is a Python wrapper around libtorch, a library written in C++ that can utilize advanced CPU magic to crunch the numbers needed for an efficient neural network calculation. When you clone the its repository, there are build scripts for different CPU architectures and various OS's. There's also a `setup.py` which does the whole process of compiling and linking `libtorch_python.so`and supplies the wrapper Python code for calling it through a Python program.

So, if you are building a purely native package that should produce a library to which other packages can link to, either statically or dynamically, you need to tell the Chaquopy `build-wheel.py` script exactly how to do this.

Let's say you want to build some simple library that has its source code in an archive. Let's say the library is named `libsimple` and the source code resides in `libsimple-0.0.1.tar.gz`. First you need to create a directory inside `chaquopy(...)/server/pypi/packages` named `chaquopy-libsimple`. The reason why we need to prepend the `chaquopy-*` part is convention; some other, purely Python package with the same name could exist that wraps our native library and it could lead to name collisions.

Now enter the `(...)/packages/chaquopy-libsimple.` directory and create a file called `meta.yaml`. The simplest way of doing this directly from bash would be something like this:

```
(build-wheel) (...)/packages/chaquopy-libsimple$ cat > meta.yaml
package:
  name: chaquopy-libsimple
  version: 0.0.1

build:
  number: 1

source:
  url: https://downloads.awesomeopensourceprojects.org/files/libraries/libsimple.tar.gz
```

finally, press CTRL+D and the contents will be written into `meta.yaml`.

So far, so good. The `build-wheel.py` script can find the archive with the source code on the internets, download it and extract it into a directory which would look something like this: `(...)/libsimple/build/0.0.1/py31-none-android31_arm64_v8a/(...)` but it hasn't got a clue how it should compile it! That's why we need a `build.sh` script. If you aren't familiar with those, files ending with `.sh` are shell script files, they are a collection of shell commands which help automate processes, for example - a build process of a program or library from source.

Suppose we examine the source tree closer and find an `INSTALL` file in which it says that our immaginary library depends on no other library and that it's installed using the "standrad UNIX configure && make && make install" to "install it onto our system". Now since we **don't** need it on our system but we want to package it into a wheel file, we search further und see that the configure script luckily supports installing it into a prefix. What this means is that when we run the configure script with a `--prefix=/path/to/where/we/want/to/install`, after the library has been built, the `make install` command is going to copy the necessary files into a directory structure relative to the given path. If you remember, we run executables (and that includes also shell scripts) with `./executable_name` so our build script needs one such line, so for our fake library, it would be `./configure --prefix=$PREFIX`. This `$PREFIX` is actually a shell variable; every identifier beginning with a dollar sign can hold data. For example, if we execute `FOO="hello world"` we can later use the `FOO` variable and the shell will replace the `$FOO` with `hello world`, e.g. `echo $FOO` prints out `hello world` in the terminal. Now there are a number of preset variables, you can print them all by issuing an `export` command; these are environment variables, which means they are available to all programs and scripts executed directly from the shell. If you need a variable to be available to other programs at runtime, instead of simply `VAR=value` we need to prepend the assignment with an `export` command, like so: `export FOO="hello world"`. Now each program that is run from the same shell can use the value of the `FOO` environment variable.

An UNIX shell (and that includes our bash) defines a number of such environment vars. But the Chaquopy `build-wheel.py` script also defines quite a few. In the root of the Chaquopy source tree there's a directory named `target` and in it a bunch of files, of which `build-common.sh` is of particular interest. This shell script defines the most important environment variables used for compiling with Android NDK and before it's run needs an env variable named `ANDROID_HOME` to be set. This variable must point to the directory in which the Android SDK is installed (this guide assumes `/opt/android-sdk` as the SDK's install path). So if we execute `export ANDROID_HOME=/opt/android-sdk/`, the `build-wheel.py` script will "source" the `build-common.sh` shell script which means that all the definitions in the `build-common.sh` - for example, the `CC` env variable which points to the C compiler we want to compile our source with (something like `/opt/android-sdk/(...)/aarch64-linux-android31-clang`) or `LDFLAGS`, the options and switches that give our linker the needed info how it should link the compiled object files into an Android executable (or in this case, an `.so` file that can be used by an App running on Android) - so, all these variables are going to be supplied to our `build.sh` script used to build our `libsimple` library. 

The `$PREFIX` var is also supplied to our script via `build-wheel.py` and by the time `build-wheel.py` executes our script the `$PREFIX` var already points to the location which the `build-wheel.py` will use to package our wheel file so it's a nice convenience which we can use and not worry about placing the files at the right location.

Now, after we've `./configure`d our little immaginary library, the `configure` script has spat out a bunch of Makefiles (or maybe just one, named simply `Makefile`). THis file describes in detail how the compiler should compile the source files into object files and how those object files should be linked together producing a library, an `.so` file. It also describes in detail the sequence of `cd` and `cp` commands (copy files/directories and change directory, respectively) effectively installing the built files into appropriate locations. So simply issuing a `make` command followed with a `make install` should, in theory, automatically compile, build and install the livbrary for us.

Theoretically, yes. Practically, the `configure` script is not perfect and cannot predict all the nuances of all the different systems and their various configurations and reliably in 100% of cases produce Makefiles which succeed all the time and one is bound to encounter errors. Some of them, the most common ones will be described in this guide. But keep in mind that it's practically impossible to predict all the errors and list them here. If you encounter one and do an extensive online search of how to solve them, open up an issue and I'll add it here. 

Good, the library is built, all is well, but we need to get rid of some files that are of no use in an Android app; our little build script has produced a bunch of `.a` files which are static library files that we don't need in our wheel file, so we `cd` to the directory where it had put them and delete them all - `cd $PREFIX/lib` followed with a `rm -rf *.a`.

The `rm -rf` is great servant - but a terrible master; if you don't know what you're doing, the `rm` command does, and it does what it's been told to do. The `-rm` switch tells it to **f**orce delete all files ending with `.a` and do it **r**ecursivelly, i.e. everything in the current working directory. Executing this command outside the `$PREFIX/lib` path could potentially damage your whole install. You have been warned: I suggest reading up on `rm` online or through man pages and making yourself familiar with such destructive force.

And voila - those were all the necessary steps to build an immaginary simple native library. So our complete `build.sh` would look like this:

```
#!/bin/bash

# This line does nothing. Lines beginning with 
# are comments.

set -eu

./configure --with-prefix=$PREFIX
make
make install

cd $PREFIX/lib
rm -rf *.a
```

The first line is called "shebang" and has nothing to do with a certain Rick Martin song. It just tells the shell that we want it executed through bash. The `set -eu` line tells the shell to crash and burn after it's encountered an error. I've described the rest in detail previously.

After you've written a *real* `build.sh` script for a *real* library, the system needs to be told to treat the file as executable, otherwise you'll most certainly get an error. You do this (outside the `build.sh`, from the shell) by executing `~/projects/chaquopy-(...)/packages/libsimple$ chmod +x build.sh`. Once again, the text before the dollar sign indicates our current working dir, the text after it the command to be executed. 

An afterthought: many open source packages also supply a `build_{architecture}.sh` script; if the `{architecture}` part is something like `android`, you're in luck, since it probably has all the switches and build options you need to make a Chaquopy Wheel. This script could be a good starting point when writing your own `build.sh` scripts.

Finally, to build our immaginary package we use the very real `build-wheel.py` script, assuming we're currently in `~/projects/chaquopy-cp310-android31/server/pypi` and execute the Python file with `(...)/server/pypi$ ./build-wheel --python 3.10 --api-level 31 --abi arm64 packages/chaquopy-libsimple`.

After a while we pretend the `build-wheel.py` script told us it successfully wrote a `chaquopy-libsimple-0.0.1-cp310-cp310-android_31_arm64_v8a.whl` wheel file. Let's dissect this filename:
    - `chaquopy-libsimple` is obviously the lib's name, with `chaquopy-` prefix added
    - `0.0.1` - its version
    - `cp310` tells us it should run on CPython (the official Python distribution from python.org)
    - `android31` is the platform, namely Android operating system with a target API of 31
    - `arm64_v8a` is the CPU architecture the native code has been compiled to

## 6. Can I use Visual Studio Code to write all this? Piping text, changing directories, copying stuff is a bit overwhelming...

Yes.

### The Why

VSCode has a 'remote' mode where it attaches to a resource other than a hard drive it has direct access to. You can also use its File Explorer to copy and move files around, make directories and even use the Ubuntu WSL2 shell without leaving the editor.

### The How

After you've activated the `build-wheel` conda environment, you can launch a vscode instance by typing `$ code .`. That's it, if the VSCode was installed in way that exposes its executable's path (i.e. code.exe is somewhere in Windows' `%PATH%` variable) after some initialization you should see VSCode in all its glory.

## 7. How do I build a wheel for a library that has its native code bundled inside the package and uses `setup.py`?

It's actually (usually) simpler than building a purely native library. We'll do it on a real world example.

### The Why

The developers of Python packages that rely on their own native code usually put their `.{c,cpp,rs}` files in a separate `src` directory relative to their package source root. Then they utilise either distutils or setuptools, Python packages that simplify this build process. The former is getting deprecated in the near future which means setuptools is going to be the go-to solution for creating Python packages; note that these two are not the only ones, although they are the most common.

### The How

For this example I have chosen a relatively new and unknown package called `structura`. It was one of the first examples I have found on PYPI's website and I managed to build it relatively uncomplicated. The process was not straightforward from the very end, but serves the illustrative purpose of researching and reading the code which others wrote in order to get things to build.

Our first stop is [the project's PYPI homepage](https://pypi.org/project/structura/). There we see what the project's all about and that it can be nice to have something like that in our app. We note the latest version (0.3.1) and since we're all about that bleedin'-edge, we go for it and write the following `meta.yaml` file, after creating a `structura` directory inside the `(...)/server/pypi` dir:

```
package:
  name: structura
  version: 0.3.1

build:
  number: 1

requirements:
  host:
    - python
```

Note that we've added a `requirements` sections to the yaml file. This tells our build environment that in order to use this package, one needs Python: this will happen on Android through Chaqopy. So we add a subsection called `host` and under it a single entry - `python`. Now let's pretend we've done our homework and looked through the source files and found no other, external dependencies that could be needed during the build process (you'll just have to trust me on this one) and we call it the day, go to our `pypi` directory and execute the `./build-wheel.py --python 3.10 --api-level 31 --abi arm packages/structura` script (you can drop the `packages/` part from `build-wheel.py` invocation but i comes in handy if you need to `cd` to the directory in case seomthing failed). 

But to our (yours, not mine) great surprise, the script fails almost immediatelly, telling us there are no `structura` packages with the version `0.3.1`, and offers us `0.3.0` as the next best candidate. Oh well, something is kinda fishy here, but anyway, let's go to our `meta.yaml` file and change the version from 0.3.1 to 0.3.0.

After we've saved the `meta.yaml` file with our minor change, we run the same `./build-wheel.py --python 3.10 --abi arm --api-level 31 structura` (note: the order of switches starting with `--*` doesn't matter, the package name should come last for a better readability). Now the build script fails again, but this time it seems like it actually did something.

If we examine the build log (scroll the terminal output up), we see that a `fatal error` occured and that our compiler couldn't find the `../include/hashmap.h` file. Judging by the relative path supplied, it seems like the source package lacks some header files. Let's investigate.

To list the content of the source file, we execute the `$ ls -ls packages/structura/bu[TAB][TAB]cp[TAB]src` command (the TAB-spamming should expand to `$ ls -ls packages/structura/build/0.3.0/cp310-cp310-android_31_arm64_v8a/src/`) and we can see that - indeed - there is no `include` folder in the package's source's root! What is going on?

Back on the projects PYPI page we see that the newest release is indeed 0.3.1. So why couldn't `pip` get it for us? If you then go to the `Download Files` link on the left, it becomes clear that the newest distributed versaion, the version 0.3.1, doesn't offer any source for download (that's why the script failed initially!), bu under it many `.whl` files. They all have different CPython versions (including a `cp310` that we want), but allso `manylinux` and `x86_64` in them so they are of no use to us (that's why the `pip` couldn't just download some of them for us and that's why we're building this wheel file in the first place!). But if you change the version to 0.3.0 under the `Release history` link and then go to the `Download files` we can see that this time there is a source distribution, and - you guessed it - it's unfortunatelly broken because it doesn't include the header files (if you downloaded the archive and extracted it manually, you'd see that it's the case).

So we can't use PYPI to get the v0.3.1's source, and the source package the PYPI offers us cannot be compiled... but we need this package badly, and ideally the latest version... let's investigate further. On the same page we can follow the Homepage link under the Project links and lo and behold - it takes us to the [project's GitHub page](https://github.com/Sekomer/structura.git). Right away it looks like we've been lucky, in the files and folders list we see an `include` folder which means we could probably compile this without much hassle, but we still need a few pieces of information to make it work.

Notice how well the author had structured their repo, there's `setup.py`, there's a fresh release when there on the right, so go ahead and copy the git repo's URL (the green `Code` button and then simply click on the 'copy' symbol right to the URL). Go back to our `meta.yaml` and add a new top section called `source` with a `git_url: https://github.com/Sekomer/structura.git` entry under it. Now the `meta.yaml` should look something like this:

```
package:
  name: structura
  version: 0.3.0

source:
  git_url: https://github.com/Sekomer/structura.git

requirements:
  host:
    - python
```

Let's fail some more (don't worry, we'll fix it quickly; failure is how one learns and it's just computers so even if you break stuff you learned a valuable lesson) and run the `build-wheel.py` again (protip: pressing UP_ARROW key on your keyboard should scroll through the command line history retrospectively; alternativelly, you could use the search function - just press CTRL+R and type wheel, it should give you the most recent command you wrote containing the word `wheel` which you can execute again just by pressing ENTER or edit before executing by pressing for example RIGHT_ARROW key). The error should look like this:

```
ceback (most recent call last):
  File "/home/vmitro/projects/chaquopy/server/pypi/./build-wheel.py", line 811, in <module>
    BuildWheel().main()
  File "/home/vmitro/projects/chaquopy/server/pypi/./build-wheel.py", line 75, in main
    self.meta = self.load_meta()
  File "/home/vmitro/projects/chaquopy/server/pypi/./build-wheel.py", line 679, in load_meta
    with_defaults(Validator)(schema).validate(meta)
  File "/home/vmitro/.local/lib/python3.10/site-packages/jsonschema/validators.py", line 130, in validate
    raise error
jsonschema.exceptions.ValidationError: {'git_url': 'https://github.com/Sekomer/structura.git'} is not valid under any of the given schemas

Failed validating 'oneOf' in schema['properties']['source']:
    {'default': 'pypi',
     'oneOf': [{'type': 'null'},
               {'const': 'pypi', 'type': 'string'},
               {'additionalProperties': False,
                'properties': {'url': {'type': 'string'}},
                'required': ['url'],
                'type': 'object'},
               {'additionalProperties': False,
                'properties': {'git_rev': {'type': ['string', 'number']},
                               'git_url': {'type': 'string'}},
                'required': ['git_url', 'git_rev'],
                'type': 'object'},
               {'additionalProperties': False,
                'properties': {'path': {'type': 'string'}},
                'required': ['path'],
                'type': 'object'}]}

On instance['source']:
    {'git_url': 'https://github.com/Sekomer/structura.git'}
```

which means we need to also write in our `meta.yaml` something called `git_rev` in addition to `git_url` (the `'required': ['git_url', 'git_rev']` line). This `git_rev` entry corresponds to the GitHub's Tags which you can see if you click on the `5 Tags` (or whatever it says by the time you're reading this) above the files and folders list right to the `main` and `1 branch`. Okay, so you're at [the projects Tags page](https://github.com/Sekomer/structura/tags) and fortunatelly there isn't a couple of thousand of them (it's not uncommon with big projects with many contributors that they have many tags and branches) so we pick the newest one (`v0.3.1`) and add it to our `meta.yaml` file under the `git_url` entry:

```
(meta.yaml, truncated)

source:
  git_url: https://github.com/Sekomer/structura.git
  git_rev: v0.3.1
```

Running the `build-wheel.py` command as already mentioned should this time build our desired Chaquopy Python package.

## 8. A `setup.py` script tries to get the numpy's version. The `build-wheel.py` script fails at importing the numpy module.

### The Why

Since we're building a wheel for a foreign system (i.e. a wheel for a package with some native code compiled for a completely different architecture - see TARGET architecture), simply calling this native code on our machine (see HOST architecture) is undubitably destined to fail. That's exactly what happens when the Python interpretter executes the `import numpy` statement, a bunch of - in this case foreign - native code tries to get loaded and called and you get a message that `multiarray could not be imported` - and that's because the core of multiarray is implemented natively (C code).

### The How

Adding this snippet of code before the `import numpy` statement in the `setup.py` file:

```
import os
import sys
import builtins
sys.path.insert(0, os.path.abspath("../requirements"))  # For numpy.distutils
builtins.__NUMPY_SETUP__ = True  # Prevent the rest of NumPy from being imported.

import numpy
```

Now, let's do it on a real package, `cftime`. Create a `cftime` directory inside Chaquopy's `pypi` directory and in it, `meta.yaml`:

```
package:
  name: cftime
  version: 1.6.2

build:
  number: 0

source:
  git_url: https://github.com/Unidata/cftime.git
  git_rev: v1.6.2rel

requirements:
  build:
    - Cython 0.29.32
  host:
    - python
    - numpy 1.24.2
```

and try and build it: `(...)/pypi$ ./build-wheel.py --python 3.10 --api-level 31 --abi arm cftime` to build for 32 bit ARM (v7a). The build should fail with an `Original error was: /home/vmitro/projects/chaquopy/server/pypi/packages/cftime/build/1.6.2/cp310-cp310-android_31_arm64_v8a/requirements/numpy/core/_multiarray_umath.so: cannot open shared object file: No such file or directory`. Now that we know that we need to add this `builtins.__NUMPY_SETUP__` trick, edit the `(...)/pypi/packages/cftime/build/1.6.2/cp310-cp310-android_31_arm64_v8a/src/setup.py` and add the text so that the the first few lines of it now look like this:

```
from __future__ import print_function

import os
import sys
import builtins
sys.path.insert(0, os.path.abspath("../requirements"))  # For numpy.distutils
builtins.__NUMPY_SETUP__ = True  # Prevent the rest of NumPy from being imported.

import numpy
```

If you run the `build-wheel.py` command again... nothing will change, because the `build-wheel.py` script extracts the sources each time it's called, effectively renderingany changes you might've done void, so we need to add a `--no-unpack` switch to it to prevent it from doing that. In continuation with the last command, it should look like this: `(...)/pypi$ ./build-wheel.py --python 3.10 --api-level 31 --abi arm cftime --no-unpack`. Now the build should succeed.

## 9. Do I need to manually edit each source file each time there's a new version? Can I somehow record my changes so that they get applied automatically?

No and yes.

### The Why

You can make patches that automatically change files after they've been extracted by the `build-wheel.py` script.o

### The How

By using the `diff` command line program. If it's not installed by default, you can add it to your Ubuntu system with `sudo apt install diff`. The whole workflow could be like this:
    - make `meta.yaml` and optionally also `build.sh` scripts
    - try to build the wheel
    - fail
    - try some changes and
    - try to build again with the `--no-unpack` option
    - fail some more
    - finally succeed
    - try to **not** run the `build-wheel.py` script without the `--no-unpack` option (it **can** happen...)
    - move the `src/` directory all the way back to `(...)/pypi/packages/mypackage`
    - now run the `build-wheel.py` **without** the `--no-unpack` option to extract the original sources
    - rename the `src/` directory in the `(...)/pypi/packages/mypackage/build/{version}/cp310-mypackage-android31-arm_v7a/` directory (not the one in `(...)/pypi/packages/mypackage`) to `src-orig`
    - move the modified `src/` directory from `(...)/pypi/packages/mypackage` to the `(...)/build/{version}/cp31-(...)-arm_v7a/` directory
    - use the `diff` command with the `u` switch from this specific `build` directory like this: `(...)arm_v7a$ diff -u src-orig/file src/file`
    - you should see the unified diff file with filenames and line numbers and also which lines should be removed (starting with `-`) and which should be added (starting with `+`)
    - verify the correctness of the patch: it should logically follow what you did in the first place, i.e. the lines in the file that should be deleted are markeed with a minus sign in front of them, the lines that you've added with a plus sign
    - if it's all well, create a `patches` directory in the `(...)/pypi/packages/mypackage` directory
    - assuming still in the `(...)-arm_v7a/` directory, execute the diff command again, this time with a redirect to file addition (`(...) > ../../../patches/chaquopy.patch`)
    - try and build the package again, also without the `--no-unpack` option

For the `cftime` package, it would look something like this, after you've applied the aformentioned changes:

```
$ cd ~/projects/chaquopy-cp310-android31/server/pypi
$ mv packages/cftime/build/1.6.2/cp310-cp310-android_31_arm64_v8a/src/ packages/cftime/
$ ./build-wheel.py --python 3.10 --abi arm64-v8a --api-level 31 packages/cftime
$ cd packages/cftime/build/1.6.2/cp310-cp310-android_31_arm64_v8a/
$ mv src/ src-orig/
$ mv ../../../src/ .
$ diff -u src-orig/setup.py src/setup.py
--- src-orig/setup.py   2023-05-13 11:01:25.000000000 +0000
+++ src/setup.py        2023-05-17 11:48:21.231831844 +0000
@@ -2,6 +2,10 @@

 import os
 import sys
+# Chaquopy
+import builtins
+sys.path.insert(0, os.path.abspath("../requirements"))  # For numpy.distutils
+builtins.__NUMPY_SETUP__ = True  # Prevent the rest of NumPy from being imported.
 import numpy

 from setuptools import Command, Extension, setup
$ mkdir ../../../patches
$ diff -u src-orig/setup.py src/setup.py > ../../../patches/chaquopy.patch
```

Now running the `build-wheel` again should succeed even without a `--no-unpack` option.
