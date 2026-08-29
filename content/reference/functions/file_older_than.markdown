---
layout: default
title: file_older_than
aliases:
  - "/reference-functions-file_older_than.html"
---

{{< CFEngine_function_prototype(filename, datestring, option) >}}

**Description:** Returns whether the file `filename` is older than some fuzzy time offset `datestring`. What file statistic is compared depends on the `option` argument. `"modify"` compares the time offset with the last modification, `"access"` with the last access and `"change"` with the last metadata change. `file_older_than` doesn't follow symlinks.

{{< CFEngine_function_attributes(filename, datestring, option) >}}

The function uses under the hood `date --date <str> +%s` from GNU coreutils, located at `/var/cfengine/bin/date`

**Example:**

```cf3
body common control
{
  bundlesequence => { "init", "main" };
}

bundle agent init
{
  files:
    "/tmp/myfile.txt" create => "true";

  commands:
    "/bin/sleep" args => 10;
}

bundle agent main
{
  classes:
    "is_8sec_old" expression => file_older_than("/tmp/myfile.txt", "8 seconds");

  reports:
    is_8sec_old::
      "/tmp/myfile.txt is older than 8 seconds";
}
```

**See also:**

- Related functions
  - [`strtotime()`][strtotime]
  - [`isnewerthan()`][isnewerthan]
  - [`isnewerthantime()`][isnewerthantime]

**History:**

- Introduced in 3.29.0
