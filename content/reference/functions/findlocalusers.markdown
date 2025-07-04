---
layout: default
title: findlocalusers
---

[%CFEngine_function_prototype(filter)%]

**Description:** Returns a data container of all local users with their attributes that are matching a filter. If no filter is specified, it will return all the local users.

[%CFEngine_function_attributes(filter)%]

The `filter` argument can be used to look up users with specific attributes that match values. The filter is a `"data"` container or `"slist"` comprised of pairs of attribute and value/regex pattern `{ "attribute1=value1", "attribute2=value2", ... }`.

The possible attributes are:
* `name`: name
* `uid`: user id
* `gid`: group id
* `gecos`: description
* `dir`: path to home directory
* `shell`: default shell



**Example:**

[%CFEngine_include_snippet(findlocalusers.cf, #\+begin_src cfengine3, .*end_src)%]

Output:

[%CFEngine_include_snippet(findlocalusers.cf, #\+begin_src\s+example_output\s*, .*end_src)%]

**Notes:**

* This function is currently only available on Unix-like systems.

**History:**

* Function added in 3.26.0.
