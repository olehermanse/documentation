---
layout: default
title: cf-net
sorting: 90
keywords: [protocol, cli]
---

`cf-net` can be used to send simple protocol commands to a policy server.
It is a Command-Line-Interface (CLI) to the CFEngine network protocol, and a standalone tool.
`cf-net` is not needed or used by any of the other binaries.
The tool can be used to send commands like `GET` and `OPENDIR` without writing policy.
It is in some ways an extremely light-weight version of `cf-agent` - policy evaluation is replaced with easy to use command line arguments.

## Command reference

[%CFEngine_include_snippet(cf-net.help, [\s]*--[a-z], ^$)%]

<!-- ** <- Terminate syntax highlighting of weird regex -->

## Bootstrapping and cf-key

`cf-net` *needs* a key-pair generated by `cf-key` to communicate with a server.
Thus, the easiest way to use cf-net is on a successfully bootstrapped client:

```console
$ sudo /var/cfengine/bin/cf-key
$ sudo /var/cfengine/bin/cf-agent --bootstrap myhostname
$ sudo /var/cfengine/bin/cf-net connect
Connected & authenticated successfully to 'myhostname'
```

(`myhostname` can also be an IP address)

All three commands above are run with sudo, so they access the same key file.

## cf-net commands
`cf-net` syntax follows the general structure:

```console
$ cf-net [global options] command [command-specific options/arguments]
```

**Note:** `cf-net` command names are *case insensitive*, so `cf-net get` and `cf-net GET` are equivalent.
All other options, arguments and file names are *case sensitive*.

### Help
**Description:** `cf-net help` is used to access help pages for `cf-net`.

**Example:**

```console
$ cf-net help
Usage: cf-net [OPTIONS] command

Options:
[...]
```

```console
$ cf-net help connect
Command:     connect
Usage:       cf-net -H 192.168.50.50,192.168.50.51 connect
Description: Checks if host(s) is available by connecting
```

**Note:** `cf-net --help` cannot be used with arguments like `cf-net help`.

### Connect
**Description:** `cf-net connect` attempts to connect and authenticate to one or more hosts running `cf-serverd`.
If no hostname is specified `policy_server.dat` is used (this is true for all `cf-net` commands).

**Example:**

```console
$ sudo /var/cfengine/bin/cf-net -H 192.168.50.50,myhostname,myhostname:5308 connect
Connected & authenticated successfully to '192.168.50.50'
Connected & authenticated successfully to 'myhostname'
Connected & authenticated successfully to 'myhostname:5308'
```

```console
$ sudo /var/cfengine/bin/cf-net connect
Connected & authenticated successfully to 'myhostname:5308'
```

### Stat
**Description:** `cf-net stat` is similar to UNIX stat, it gives information about a file/directory.

**Example:**

```console
$ cf-net stat /var/cfengine/masterfiles/update.cf
myhostname:5308:'/var/cfengine/masterfiles/update.cf' is a regular file
$ cf-net stat masterfiles
myhostname:5308:'masterfiles' is a directory
```

```console
$ cf-net -I stat masterfiles
    info: Inform log level enabled
    info: Detailed stat output:
mode  = 40700,  size = 4096,
uid   = 0,      gid = 0,
atime = 1495551229,     mtime = 1495551172
myhostname:5308:'masterfiles' is a directory
```

### Get
**Description:** Performs a `stat` and then `get` command, downloading the specified file to the current working directory.
Use the `-o` option to specify output path.

**Example:**

```console
$ cf-net get masterfiles/update.cf
$ ls
cfengine  update.cf
```

```console
$ cf-net get -o test.cf masterfiles/update.cf
$ ls
cfengine  test.cf  update.cf
```

**Note:** The `-o` option must come before the remote filename:

### Opendir
**Description:** Similar to UNIX `ls`, prints everything inside a directory, in no particular order.

**Example:**

```console
$ cf-net opendir masterfiles
services
cf_promises_validated
cfe_internal
..
controls
templates
cf_promises_release_id
lib
inventory
update.cf
promises.cf
.
```
