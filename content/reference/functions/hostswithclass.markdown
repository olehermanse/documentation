---
layout: default
title: hostswithclass
---

**This function is only available in CFEngine Enterprise.**

[%CFEngine_function_prototype(class, field)%]

**Description:** Returns a list from the CFEngine Database with the information
`field` of hosts on which `classs` is set.

On CFEngine Enterprise, this function can be used to return a list of
hostnames, ip-addresses or public key SHAs of hosts that have a given class.

**Note:** This function only works locally on the hub, but allows the hub to construct custom
configuration files for (classes of) hosts. Hosts are selected based on the
classes set during the most recently collected agent run.

[%CFEngine_function_attributes(class, field)%]

**Example:**

```cf3
bundle agent debian_hosts
{
vars:

  am_policy_hub::
    "host_list" slist => hostswithclass( "debian", "name" );

files:
  am_policy_hub::
    "/tmp/master_config.cfg"
         edit_line => insert_lines("host=$(host_list)"),
            create => "true";
}
```

**History:** Was introduced in 3.3.0, Nova 2.2.0 (2012). The `hostkey` field was introduced in 3.26.0

**See also:** `hubknowledge()`, `remotescalar()`, `remoteclassesmatching()`
