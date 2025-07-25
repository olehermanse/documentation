---
layout: default
title: measurements
---

By default, CFEngine's monitoring component `cf-monitord` records performance
data about the system. These include process counts, service traffic, load
average and CPU utilization and temperature when available. It also records a
three year trend summary based any 'shift'-averages.

Custom `measurements` promises can monitor or log very specific user data
through a generic interface. The end-result is to either generate a periodic
time series, like the above mentioned values, or to log the results to
custom-defined reports.

Promises of type `measurement` are written just like all other promises within a
bundle destined for the agent concerned, in this case `monitor`. However, it is
not necessary to add them to the `bundlesequence`, because `cf-monitord`
executes all bundles of type `monitor`.

```cf3
bundle monitor self_watch
{
  measurements:
    # Follow a special process over time
    # using CFEngine's process cache to avoid resampling

    # Example content from /var/cfengine/state/cf_rootprocs
    #USER                             PID         PPID          PGID          %CPU         %MEM        VSZ        NI         RSS    TTY      NLWP STIME     ELAPSED     TIME COMMAND
    #root                             19103       1             19103         0.2          2.1         71716      0          10676  ?           1 18:09       40:13 00:00:06 /var/cfengine/bin/cf-monitord --no-fork

    # match_value:
    #root \s+                         [0-9.]+ \s+ [0-9.]+  \s+  [0-9.]+ \s+   [0-9.]+ \s+  [0-9.]+ \s+ [0-9]+ \s+ [0-9]+ \s+ ([0-9]+) .*"


     "/var/cfengine/state/cf_rootprocs"

        handle => "cf_monitord_RSS",
        stream_type => "file",
        data_type => "int",
        history_type => "weekly",
        units => "kb",
        match_value => proc_value(".*cf-monitord.*",
        "root\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+\s+[0-9.]+\s+[0-9.]+\s+([0-9]+).*"),
        comment => "The ammount of memory (RSS or Resident Set Size) cf-monitored is consuming";
}

body match_value proc_value(x,y)
{
  select_line_matching => "$(x)";
  select_multiline_policy => "sum";
  extraction_regex => "$(y)";
}
```


```cf3
bundle monitor watch_diskspace
{
  measurements:
    # Discover disk device information
    "/bin/df"
      handle => "free_diskspace_watch",
      stream_type => "pipe",
      data_type => "slist",
      history_type => "static",
      units => "device",
      match_value => file_systems;

}

body match_value file_systems
{
  select_line_matching => "/.*";
  extraction_regex => "(.*)";
}
```

The general pattern of these promises is to decide whether the source of the
information is either a file or pipe, determine the data type (integer, string
etc.), specify a pattern to match the result in the file stream and then specify
what to do with the result afterwards.

**History:**

* Custom measurements open sourced in 3.12.0

## Architecture

Information gathered by `cf-monitord` is stored in `${sys.statedir}/env_data` to
share with other agents like `cf-agent` and `cf-promises` which both provide three
variables per measurement with different prefixes: `value_` for the latest measurement,
`av_` for the running average and `dev_` for the standard deviation of the running average.

The standard measurements and their variable names are listed in [`mon` special variables][mon].

The data over time is stored in `${sys.statedir}/cf_observations.lmdb` which can be examined
most easily with the `cf-check` command:

```
cf-check dump /var/cfengine/state/cf_observations.lmdb
```

By default in the [Masterfiles Policy Framework][Masterfiles Policy Framework], `cf-serverd` uses two variables, `def.default_data_select_host_monitoring_include` and `def.default_data_select_policy_hub_monitoring_include` to [configure which measurements will be included in enterprise reporting][mpf-configure-measurement-collection].

On the hub side, reports are collected and measurements data is inserted into the [`MonitoringHG`][cfdb#Table: MonitoringYrMeta]  [`MonitoringMgMeta`][cfdb#Table: MonitoringMgMeta] and [`MonitoringYrMeta`][cfdb#Table: MonitoringYrMeta] tables of the Enterprise Hub database.

A diagnostic query to run with a [Custom Report in Mission Portal][Reporting UI].

Select all unique observables in the database:

```sql
SELECT distinct(observable) FROM monitoringmgmeta;
```

To see which measures are collected for each host, select all data from this
table and then use report result filters to examine a particular host or measure's having
data or not.

```sql
SELECT * FROM monitoringmgmeta;
```

Measurement data is presented in Mission Portal in the [`Measurements App`][Measurements App] and in the ```Measurements``` section of the [`Host info page`][Hosts#Host info].

When policy is changed in regards to monitor bundles, both `cf-monitord` _and_ `cf-serverd` should be restarted in order to receive the updated policy.

It is possible to [configure masterfiles to restart `cf-monitord` when variables which affect it's configuration are changed][mpf-configure-component-restart].

All measurements historical data is stored in `${sys.statedir}/cf_observations.lmdb`. This is where reporting data is pulled from.

`${sys.statedir}/env_data` is a current snapshot of measurement values which agents (`cf-agent` and `cf-promises`) use to generate the [special monitor variables][mon].

`${sys.statedir}/ts_key` is the source for the list of observables/measurements used in the system. This file includes the integer id, name and other meta data in a slightly human readable form, for example:

```
0,users,Users with active processes - including system users,average users per 2.5 mins,0.000,100.000,1
```

The `ts_key` file should not be altered.

Note that if a measurement has _always_ had a value of zero it will not be reported and so not available in Mission Portal Measurements or Host info pages.

It is important to specify a promise `handle` for measurement promises, as the
names defined in the handle are used to determine the name of the log file or
variable to which data will be reported. Log files are created under
`WORKDIR/state`. Data that have no history type are stored in a special variable
context called `mon`, analogous to the system variables in sys. Thus the values
may be used in other promises in the form `$(mon.handle)`.

***

## Attributes

### stream_type

**Description:** The datatype being collected.

**Default:**  ```pipe```

CFEngine treats all input using a stream abstraction. The preferred interface
is files, since they can be read without incurring the cost of a process.
However pipes from executed commands may also be invoked.

**Type:** (menu option)

**Allowed input range:**

```cf3
pipe
file
```

**Example:**

```cf3
stream_type => "pipe";
```

### data_type

**Description:** The datatype being collected.

When CFEngine observes data, such as the attached partitions in the example above, the datatype determines how that data will be handled. Integer and real values, counters etc., are recorded as time-series if the history type is 'weekly', or as single values otherwise. If multiple items are matched by an observation (e.g. several lines in a file match the given regular expression), then these can be made into a list by choosing `slist`, else the first matching item will be selected.

**Type:** (menu option)

**Allowed input range:**

```
counter
int
real
string
slist
```

**Example:**

```cf3
"/bin/df"

    handle => "free_disk_watch",
    stream_type => "pipe",

    data_type => "slist",

    history_type => "static",
    units => "device",
    match_value => file_systems,
    action => sample_min(10,15);
```

### history_type

**Description:** Whether the data can be seen as a time-series or just an
isolated value

**Type:** (menu option)

**Allowed input range:**

* `scalar`

A single value, with compressed statistics is retained. The value of the
data is not expected to change much for the lifetime of the daemon (and
so will be sampled less often by cf-monitord).

* `static`

A synonym for 'scalar'.

* `log`

The measured value is logged as an infinite time-series in
`$(sys.workdir)/state/<handle>_measure.log`.

* `weekly`

A standard CFEngine two-dimensional time average (over a weekly period)
is retained.

**Example:**

```cf3
"/proc/meminfo"

     handle => "free_memory_watch",
     stream_type => "file",
     data_type => "int",
     history_type => "weekly",
     units => "kB",
     match_value => free_memory;
```

**Notes:**

* Measurements with history type `weekly` _are collected_ by CFEngine Enterprise reporting.
* Measurements with history type `static` are _not collected_ by CFEngine Enterprise reporting.
* Measurements with history type `scalar` are _not collected_ by CFEngine Enterprise reporting.
* Measurements with history type `log` are _not collected_ by CFEngine Enterprise reporting.

### units

**Description:** The engineering dimensions of this value or a note about
its intent used in plots

This is an arbitrary string used in documentation only.

**Type:** `string`

**Allowed input range:** (arbitrary string)

**Example:**

```cf3
"/var/cfengine/state/cf_rootprocs"

   handle => "monitor_self_watch",
   stream_type => "file",
   data_type => "int",
   history_type => "weekly",
   units => "kB",
   match_value => proc_value(".*cf-monitord.*",

      "root\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+([0-9]+).*");
```

### match_value

**Type:** `body match_value`

**See also:** [Common body attributes][Promise types#Common body attributes]

#### select_line_matching

**Description:** Regular expression for matching line location

The expression is [anchored][anchored], meaning it must match a whole line, and not
a fragment within a line.

This attribute is mutually exclusive of `select_line_number`.

**Type:** `string`

**Allowed input range:** `.*`

**Example:**

```cf3
# Editing

body location example
{
select_line_matching => "Expression match.* whole line";
}

# Measurement promises

body match_value example
{
select_line_matching => "Expression match.* whole line";
}
```

#### select_line_number

**Description:** Read from the n-th line of the output (fixed format)

This is mutually exclusive of [`select_line_matching`][measurements#select_line_matching].

**Type:** `int`

**Allowed input range:** `0,99999999999`

**Example:**

```cf3
body match_value find_line
{
select_line_number => "2";
}
```

#### extraction_regex

**Description:** Regular expression that should contain a single
back-reference for extracting a value.

A single parenthesized back-reference should be given to lift the value to be
measured out of the text stream. The regular expression is [unanchored][unanchored], meaning
it may match a partial string

**Type:** `string`

**Allowed input range:** (arbitrary string)

**Example:**

```cf3
body match_value free_memory
{
select_line_matching => "MemFree:.*";
extraction_regex => "MemFree:\s+([0-9]+).*";
}
```

#### track_growing_file

**Description:** If true, CFEngine remembers the position to which is last
read when opening the file, and resets to the start if the file has
since been truncated

This option applies only to file based input streams. If this is true,
CFEngine treats the file as if it were a log file, growing continuously.
Thus the monitor reads all new entries since the last sampling time on
each invocation. In this way, the monitor does not count lines in the
log file redundantly.

This makes a log pattern promise equivalent to something like tail -f
logfile | grep pattern in Unix parlance.

**Type:** [`boolean`][boolean]

**Example:**

```cf3
bundle monitor watch
{
measurements:

   "/home/mark/tmp/file"

         handle => "line_counter",
    stream_type => "file",
      data_type => "counter",
    match_value => scan_log("MYLINE.*"),
   history_type => "log",
         action => sample_rate("0");

}

#

body match_value scan_log(x)
{
select_line_matching => "^$(x)$";
track_growing_file => "true";
}

#

body action sample_rate(x)
{
ifelapsed => "$(x)";
expireafter => "10";
}
```


#### select_multiline_policy

**Description:** Regular expression for matching line location

This option governs how CFEngine handles multiple matching lines in the
input stream. It can average or sum values if they are integer or real,
or use first or last representative samples. If non-numerical data types
are used only the first match is used.

**Type:** (menu option)

**Allowed input range:**

```
average
sum
first
last
```

**Example:**

```cf3
body match_value myvalue(xxx)
{
 select_line_matching => ".*$(xxx).*";
 extraction_regex => "root\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+).*";
 select_multiline_policy => "sum";
}
```

**History:** Was introduced in 3.4.0 (2012)
