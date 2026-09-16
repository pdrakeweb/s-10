# s-10

ESPHome configs for our GL-S10 Bluetooth proxies. `s10.yaml` holds the shared
device config (ethernet, Bluetooth proxy, LEDs, buttons); each target
(`site-a-s10.yaml`, `site-b-s10.yaml`, ...) just sets a `name` and `ip_address`
substitution and includes it.

## Prerequisites

- Python with the `esphome` CLI installed (`pip install esphome`).
- Targets must already be flashed and reachable on the network — deploys go
  out over OTA (`esphome update-all` uploads with `--device OTA`), not USB.

## Everyday workflow

Run these from the repo root. Three steps: update the tool, pull the config
source, then build and push it to the devices.

### 1. Update to the latest bins

This updates the `esphome` command-line tool itself (the compiler/uploader),
not this repo's config:

```powershell
pip install --upgrade esphome
```

### 2. Pull the latest source

Pull the latest config from git:

```powershell
git pull
```

(This repo has no remote configured yet — once one exists, `git remote add
origin <url>` first, or `git pull origin master` explicitly.)

`s10.yaml` also pulls in `github://blakadder/bluetooth-proxies/gl-s10.yaml@main`
via `dashboard_import` — that's a second, separate "source" ESPHome fetches
on its own. ESPHome may cache it (and other remote/external components)
under `.esphome/`; if you need to force a fresh pull instead of relying on
the cache, wipe it first:

```powershell
esphome clean-all site-a-s10.yaml site-b-s10.yaml
```

Optionally validate/compile without pushing anything, to sanity-check what
you just pulled:

```powershell
esphome config site-a-s10.yaml    # just check the config is valid
esphome compile site-a-s10.yaml   # compile without uploading
```

### 3. Build and push

```powershell
# compile + OTA upload, one target
esphome update-all site-a-s10.yaml

# compile + OTA upload + tail logs, one target
esphome run site-a-s10.yaml

# compile + OTA upload, every target at once
esphome update-all site-a-s10.yaml site-b-s10.yaml
```

Or run all three steps in one go with the wrapper script, which discovers
every `*-s10.yaml` target file automatically:

```powershell
.\deploy-all.ps1
```

Options:

```powershell
.\deploy-all.ps1 -SkipUpgrade            # skip step 1 (pip install --upgrade esphome)
.\deploy-all.ps1 -SkipPull               # skip step 2 (git pull)
.\deploy-all.ps1 -Targets site-a-s10.yaml  # deploy to just one target
```

> Don't point `update-all` at the whole directory (`esphome update-all .`) —
> it globs every `*.yaml` file it finds, including the shared `s10.yaml`
> base file, which isn't a standalone device config and will just fail.
> Pass the target files explicitly (or use `deploy-all.ps1`, which does this
> for you).

## Adding a new target

1. Copy `site-a-s10.yaml` to `<name>-s10.yaml`, set `name` and `ip_address`.
2. `deploy-all.ps1` will pick it up automatically since it globs `*-s10.yaml`.
