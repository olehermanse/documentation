---
layout: default
title: strtotime
aliases:
  - "/reference-functions-strtotime.html"
---

{{< CFEngine_function_prototype(date_string) >}}

**Description:** Parses a `date_string` to the number of seconds since the Epoch

{{< CFEngine_function_attributes(date_string) >}}

The function uses under the hood `date --date <str> +%s` from GNU coreutils, located at `/var/cfengine/bin/date`

**Example:**

```cf3
bundle agent main
{
  vars:
    "next_monday" int => strtotime("next Monday");
}
```

**See also:**

- Related functions
  - [`strftime()`][strftime]

**History:**

- Introduced in 3.29.0
