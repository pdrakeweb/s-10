# s-10

ESPHome configs for GL-S10 Bluetooth proxies. `s10.yaml` holds the shared
device config (ethernet, Bluetooth proxy, LEDs, buttons). Each device target
is a small `<name>-s10.yaml` file that sets substitutions (`name`,
`ip_address`, `gateway`, `subnet`) and includes `s10.yaml`.

## Device targets live in `sites/`

Real targets are deployment-specific (names, addresses), so they're kept out of
this repo: `sites/` is gitignored. Put your targets there — either a plain
folder, or a junction/symlink to wherever you keep them (e.g. a private repo).

```powershell
mkdir sites
Copy-Item examples\example-s10.yaml sites\garage-s10.yaml   # then edit the values
```

Targets include `../s10.yaml`, so they must sit one folder below the repo root
(`sites/` or `examples/`). If `sites/` needs a `secrets.yaml` (for `!secret`),
it goes in `sites/` too — ESPHome reads it from the target's folder.

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

```powershell
git pull
```

If `sites/` is a link into another git repo, pull that repo too
(`git -C sites pull` — git follows the link to the real repo).
`deploy-all.ps1` does both.

`s10.yaml` also pulls in `github://blakadder/bluetooth-proxies/gl-s10.yaml@main`
via `dashboard_import` — that's a second, separate "source" ESPHome fetches
on its own. ESPHome may cache it (and other remote/external components)
under `.esphome/` next to the targets; if you need to force a fresh pull
instead of relying on the cache, wipe it first:

```powershell
esphome clean-all sites/garage-s10.yaml
```

Optionally validate/compile without pushing anything, to sanity-check what
you just pulled:

```powershell
esphome config sites/garage-s10.yaml    # just check the config is valid
esphome compile sites/garage-s10.yaml   # compile without uploading
```

### 3. Build and push

```powershell
# compile + OTA upload, one target
esphome update-all sites/garage-s10.yaml

# compile + OTA upload + tail logs, one target
esphome run sites/garage-s10.yaml

# compile + OTA upload, several targets at once
esphome update-all sites/garage-s10.yaml sites/shed-s10.yaml
```

Or run all three steps in one go with the wrapper script, which discovers
every `sites/*-s10.yaml` target automatically:

```powershell
.\deploy-all.ps1
```

Options:

```powershell
.\deploy-all.ps1 -SkipUpgrade               # skip step 1 (pip install --upgrade esphome)
.\deploy-all.ps1 -SkipPull                  # skip step 2 (git pull)
.\deploy-all.ps1 -Targets garage-s10.yaml   # deploy to just one target (looked up in sites/)
```

> Don't point `update-all` at a whole directory (`esphome update-all .`) —
> it globs every `*.yaml` file it finds, including the shared `s10.yaml`
> base file, which isn't a standalone device config and will just fail.
> Pass the target files explicitly (or use `deploy-all.ps1`, which does this
> for you).

## Adding a new target

1. Copy `examples/example-s10.yaml` to `sites/<name>-s10.yaml` and set the
   substitutions.
2. `deploy-all.ps1` will pick it up automatically since it globs
   `sites/*-s10.yaml`.
