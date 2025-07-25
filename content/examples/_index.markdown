---
layout: default
title: Examples and tutorials
sorting: 60
---

## Links to examples

* [Example snippets][Example snippets]: This section is divided into topical areas and includes many examples of policy and promises. Each of the snippets can be easily copied or downloaded to a policy server and used as is.

**Note:** CFEngine also includes a small set of examples by default, which can be found in `/var/cfengine/share/doc/examples`.

* [Enterprise API examples][Enterprise API examples]
* [Tutorials][Tutorials]

See also:

* [Tutorial for running examples][Examples and tutorials#Tutorial for running examples]
  * ["Hello world" policy example][Examples and tutorials#"Hello world" policy example]
  * [Activate a bundle manually][Examples and tutorials#Activate a bundle manually]
  * [Make the example stand alone][Examples and tutorials#Make the example stand alone]
  * [Make the example an executable script][Examples and tutorials#Make the example an executable script]
  * [Integrating the example into your main policy][Examples and tutorials#Integrating the example into your main policy]

## Tutorial for running examples

In this tutorial, you will perform the following:

* Create a simple "Hello World!" example policy file
* Make the example a standalone policy
* Make the example an executable script
* Add the example to the main policy file (`promises.cf`)

**Note** if your CFEngine administrator has enabled continuous deployment of the policy from a Version control System, your changes may be overwritten!

### "Hello world" policy example

Policies contain **bundles**, which are collections of promises. A **promise** is a declaration of
intent. Bundles allow related promises to be grouped together, as illustrated in the steps that follow.

Following these steps, you will login to your policy server via the SSH protocol, use the vi command line editor to create a policy file named hello_world.cf, and create a bundle that calls a promise to display some text.

1. Log into a running server machine using ssh (PuTTY may be used if using Windows).
2. Type ```sudo su``` for super user (enter your password if prompted).
3. To get to the __masterfiles__ directory, type ```cd /var/cfengine/masterfiles```.
4. Create the file with the command: ```vi hello_world.cf ```
5. In the vi editor, enter ```i``` for "Insert" and enter the following content (ie. copy and paste from a text editor):
   ```cf3
   [file=hello_world.cf]
   bundle agent hello_world
   {
     reports:
       any::
         "Hello World!";
   }
   ```
6. Exit the "Insert" mode by pressing the "esc" button. This will return to the command prompt.
7. Save the changes to the file by typing ```:w``` then "Enter".
8. Exit vi by typing ```:q``` then "Enter".

In the policy file above, we have defined an **agent bundle** named `hello_world`. Agent
bundles are only evaluated by **cf-agent**, the [agent component][cf-agent] of CFEngine.

This bundle [promises][Promise types] to [report][reports] on any [class of hosts][Classes and decisions].

### Activate a bundle manually

Activate the bundle manually by executing the following command at prompt:

```command
/var/cfengine/bin/cf-agent --no-lock --file ./hello_world.cf --bundlesequence hello_world
```

This command instructs CFEngine to ignore [locks][Controlling frequency], load
the `hello_world.cf` policy, and activate the `hello_world` bundle. See the output below:

```command
/var/cfengine/bin/cf-agent --no-lock --file ./hello_world.cf --bundlesequence hello_world
```

```output
2013-08-20T14:03:43-0500   notice: R: Hello World!
```

As you get familiar with CFEngine, you'll probably start shortening this command to this equivalent:

```command
/var/cfengine/bin/cf-agent -Kf ./hello_world.cf -b hello_world
```

Note the full path to the binary in the above command. CFEngine stores its binaries in `/var/cfengine/bin`
on Linux and Unix systems. Your path might vary depending on your platform and the packages your are using.
CFEngine uses /var because it is one of the Unix file systems that resides locally.
Thus, CFEngine can function even if everything else fails
(your other file systems, your network, and even system binaries) and possibly repair problems.

### Make the example stand alone

Instead of specifying the bundle sequence on the command line (as it was above), a [body common
control][Components#Common control] section can be added to
the policy file. The **body common control** refers to those promises that are hard-coded into
all CFEngine components and therefore affect the behavior of all components. Note that only
 one `body common control` is allowed per agent activation.

Go back into vi by typing "vi" at the prompt. Then type ```i``` to insert
 __body common control__ to `hello_world.cf`. Place it above __bundle agent hello_world__, as
shown in the following example:

```cf3 {file="hello_world.cf"}
body common control
{
  bundlesequence => { "hello_world" };
}

bundle agent hello_world
{
  reports:
    any::
      "Hello World!";
}
```

Now press "esc" to exit the "Insert" mode, then type ```:w``` to save the file changes and "Enter".
Exit vi by typing ```:q``` then "Enter." This will return to the prompt.

Execute the following command:

```command
/var/cfengine/bin/cf-agent --no-lock --file ./hello_world.cf
```

```output
notice: R: Hello World!
```

**Note:** It may be necessary to add a reference to the standard library within the body common control section, and remove the `bundlesequence` line.
Example:

```cf3 {file="hello_world.cf"}
body common control
{
  inputs => {
    "libraries/cfengine_stdlib.cf",
  };
}
```

### Make the example an executable script

Add the ```#!``` marker ("shebang") to `hello_world.cf` in order to invoke CFEngine policy as an executable script:
Again type "vi" then "Enter" then ```i``` to insert the following:

```cf3
#!/var/cfengine/bin/cf-agent --no-lock
```

Add it before __body common control__, as shown below:

```cf3 {file="hello_world.cf"}
#!/var/cfengine/bin/cf-agent --no-lock
body common control
{
  bundlesequence => { "hello_world" };
}

bundle agent hello_world
{
  reports:
    any::
      "Hello World!";
}
```

Now exit "Insert" mode by pressing "esc". Save file changes by typing ```:w``` then "Enter"
then exit vi by typing ```:q``` then "Enter". This will return to the prompt.

Make the policy file executable:

```command
chmod +x ./hello_world.cf
```

And it can now be run directly:

```command
./hello_world.cf
```

```output
2013-08-20T14:39:34-0500   notice: R: Hello World!
```


### Integrating the example into your main policy

Make the example policy part of your main policy by
doing the following on your policy server:

1. Ensure the example is located in `/var/cfengine/masterfiles`.

2. If the example contains a `body common control` section, delete it. That
section will look something like this:

   ```cf3
   body common control
   {
     bundlesequence  => { "hello_world" };
   }
   ```

You cannot have duplicate control bodies (i.e. two
agent control bodies, one in the main file and one
in the example) as CFEngine won't know which it
should use and they may conflict.

To resolve this, copy the contents of the control body section from the
example into the identically named control body section in the main policy
file `/var/cfengine/masterfiles/promises.cf`and then remove the control body
from the example.

3. Insert the example's bundle name in the `bundlesequence` section
    of the main policy file `/var/cfengine/masterfiles/promises.cf`:

    ```cf3
    bundlesequence => {
        ...
        "hello_world",
        ...
    };
    ```

4. Insert the policy file name in the [`inputs`][Components#inputs] section of the main policy file
    `/var/cfengine/masterfiles/promises.cf`:

    ```cf3
    inputs => {
        ...
        "hello_world.cf",
        ...
    };
    ```

5. You must also remove any inputs section from the example that
   includes the external library:

    ```cf3
    inputs => {
        "libraries/cfengine_stdlib.cf"
    };
    ```

    This is necessary, since `cfengine_stdlib.cf` is already included
    in the inputs section of the master policy.

6. The example policy will now be executed every five minutes along with the rest
of your main policy.

**Notes:** You may have to fill the example with data before it will work.
For example, the LDAP query in `active_directory.cf` needs a domain name.
In the variable declaration, replace "cftesting" with your domain name:

[%CFEngine_include_snippet(integrating_the_example_into_your_main_policy.cf, .* )%]
