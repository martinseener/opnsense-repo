# OPNsense plugin repository by Martin Seener

A small FreeBSD package repository with OPNsense plugins, served from GitHub Pages. Once added,
the plugins show up under **System → Firmware → Plugins** like the official ones and update
together with them.

| Plugin | Description |
|---|---|
| [os-wildcard-aliases](https://github.com/martinseener/os-wildcard-aliases) | Firewall aliases for wildcard FQDNs like `*.blob.core.windows.net`, learned from DNS answers |

These plugins are not part of OPNsense and not supported by the OPNsense project. Use them at your
own risk, and take a snapshot or configuration backup before installing.

## Add the repository

On the firewall, as root (console option 8 or ssh):

```sh
fetch -o /usr/local/etc/pkg/repos/martinseener.conf https://martinseener.github.io/opnsense-repo/martinseener.conf
pkg update
```

Then install the plugin in the GUI (System → Firmware → Plugins; click "Check for updates" first
if it isn't listed yet), or with `pkg install os-wildcard-aliases`.

List what the repository offers, and what you installed from it:

```sh
pkg search -r martinseener -g 'os-*'
pkg query -a '%R %n-%v' | grep martinseener
```

## Remove the repository

Remove the plugins first (GUI or `pkg delete os-wildcard-aliases`), then:

```sh
rm /usr/local/etc/pkg/repos/martinseener.conf
pkg update
```

Removing the repository alone keeps installed plugins, they just stop getting updates.

## How it works

`plugins.conf` lists each plugin with its source repository and tag. On every push to `main` the
workflow starts a FreeBSD VM, drops each plugin into a checkout of
[opnsense/plugins](https://github.com/opnsense/plugins) and builds it with its `make package`,
exactly like an official plugin, including the install and removal hooks. `pkg repo` then
creates the index, and GitHub Pages serves the result under
`https://martinseener.github.io/opnsense-repo/repo`.

The plugins contain no compiled code, so each is built once for all FreeBSD versions and
architectures (`PLUGIN_NO_ABI`).

The repository is not signed: integrity relies on HTTPS and on this GitHub account.

## Release a new plugin version

1. In the plugin repository: bump `PLUGIN_VERSION` in its `Makefile`, commit, and tag it
   (e.g. `v0.2`), then push the tag.
2. Here: change the tag in `plugins.conf` and push. The workflow builds and publishes it; firewalls
   see the update with their next firmware check.

To build locally on a FreeBSD or OPNsense box: `sh build.sh` (needs git), the result is in `public/`.
