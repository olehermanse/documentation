---
layout: default
title: file control
sorting: 100
---


```cf3
body file control
{
namespace => "name1";
}

bundle agent private
{
....
}
```

**History:** Was introduced in 3.4.0, Enterprise 3.0.0 (2012)

This directive can be given multiple times within any file,
outside of body and bundle definitions.

Only [soft classes][Classes and decisions] from common bundles can
be used in class decisions inside `file control bodies`.

### inputs

**Description:** The `inputs` slist contains additional filenames to parse for promises.

The filenames specified are all assumed to be relative to the directory
of the file which references them. Use an absolute file name if you need an absolute path.
Use `sys.libdir` (absolute library path), `sys.local_libdir` (library path relative to the
current masterfiles), and `this.promise_dirname` (the directory of the currently processed
file) to avoid hard-coding paths.

Note that in `this.` variables are not available in `body file control` or `body common control`
but this can be worked around with a `bundle common` vars promise as follows:

```cf3
# one.cf
bundle common one
{
  vars:
    "inputs" slist => { "$(this.promise_dirname)/two.cf" };
}

body file control
{
  inputs => { "@(one.inputs)" };
}

bundle agent main
{
  methods:
    "two";
}
```

```cf3
# two.cf
bundle agent two
{
  reports:
    "hello, from $(this.promise_filename)";
}
```

```sh
$ cf-agent -KIf ./one.cf
R: hello, from /home/agent/./two.cf
```


**See also:** [`inputs`][Components#inputs] in
[`body common control`][Components]

**History:** Was introduced in CFEngine 3.6.0

### namespace

**Description:** The namespace string identifies a private namespace
to switch to in order to protect the current file from duplicate definitions.

**Type:** `string`

**Allowed input range:** `[a-zA-Z0-9_$(){}\[\].:]+`

**Example:**

```cf3
body file control
{
namespace => "name1";
}
```

**Notes:**

**History:** Was introduced in 3.4.0, Enterprise 3.0.0 (2012)

This directive can be given within any file, outside of body and bundle
definitions, to change the [namespace][namespaces] of subsequent bundles
and bodies. A namespace applies until the next namespace declaration in a
file, or until the end of a file. This is similar to how class expressions
apply until the next class expression or end of bundle.

**See also:** `namespaces`
