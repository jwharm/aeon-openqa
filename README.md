# Instructions to setup and run Aeon openQA tests

Pull request: https://github.com/os-autoinst/os-autoinst-distri-opensuse/pull/24395

Below are my notes and workarounds.

## Create a distrobox

OpenQA has a ready-to-run container image, but for reasons I cannot remember anymore I didn't get it to work, so I'm using a distrobox here.

Create a distrobox that supports services (--init) and root privileges (--root). We need a rootful distrobox because the openQA bootstrap script installs the web UI on port 80, and I haven't found an easy way to change that.

```
distrobox create openqa --init --root
distrobox enter --root openqa
```

On my machine, there's an issue with the tty in a rootful distrobox. If you notice an error message about `"inappropriate ioctl for device"`, use `script` as a workaround:

```
script /dev/null
```

## Bootstrap openQA

Install the openQA bootstrap script:

```
sudo zypper in openQA-bootstrap
```

The bootstrap script doesn't work in distrobox, because it tries to update `/etc/hosts`, which is read-only in distrobox.

As a workaround, edit the bootstrap script (located in `/usr/share/openqa/script/openqa-bootstrap`). Comment-out line 166 that updates `/etc/hosts`.

Run the openQA-bootstrap script:

```
sudo /usr/share/openqa/script/openqa-bootstrap
```

When the bootstrap script succeeds, openQA will be installed, and the web UI is available under `http://localhost/`

## Add Aeon tests

The bootstrap script has cloned the opensuse tests ("osado") in `/var/lib/openqa/tests/opensuse`. We will now add Aeon to it. 

* **TODO:** Obviously, this part is going to be a PR, instead of manually copying files

First, create the "aeon" product under products/aeon:

```
sudo mkdir /var/lib/openqa/tests/opensuse/products/aeon
```

Copy the files `templates` and `main.pm` from the `products/aeon` directory in this repo to the directory `/var/lib/openqa/tests/opensuse/products/aeon` that you just created.

Copy the needles to `/var/lib/openqa/tests/opensuse/products/opensuse/needles`.

Change the owner of the needles. This is required to be able to overwrite them with new needles in the needle editor of the openQA web UI:

```
sudo chown -R geekotest:geekotest /var/lib/openqa/tests/opensuse/products/opensuse/needles/*
```

Run the `templates` script. It is a shell script, so you can execute "`./templates`" and it will add the definitions to the openQA database.

Create lib/Distribution/Aeon directory:

```
sudo mkdir /var/lib/openqa/share/tests/opensuse/lib/Distribution/Aeon
```

Copy `RC3.pm` into this directory (find it in lib/Distribution/Aeon).

Overwrite `DistributionProvider.pm` and `version_utils.pm` in `/var/lib/openqa/share/tests/opensuse/lib` with the files from this repository.

Create `tests/aeon` directory:

```
sudo mkdir /var/lib/openqa/share/tests/opensuse/tests/aeon
```

Copy `tik.pm` and `firstboot.pm` into this directory. These scripts contain the actual tests, and are called from the `main.pm` script we copied earlier.

Finally, create an `aeon` symlink to osado. A similar link is already present for `sle`.

```
sudo ln -s opensuse /var/lib/openqa/share/tests/aeon
```

## Run the tests

### First run: Automatically download the image

To start a test with the online hosted installer image, we must first allow `opensuse.org` as a safe domain in `openqa.ini`:

* Copy `etc/openqa/01-enable-download.ini` into `/etc/openqa/openqa.ini.d/`
* Run `sudo systemctl restart openqa-gru openqa-worker@1 openqa-webui` to load the new config

Run the test, same as above, but use the `HDD_1_DECOMPRESS_URL` argument to download and decompress the image:

```
openqa-cli api -X POST isos \
         DISTRI=aeon \
         VERSION=RC3 \
         FLAVOR=IMAGE \
         ARCH=x86_64 \
         NEEDLES_DIR=/var/lib/openqa/tests/opensuse/products/opensuse/needles \
         HDD_1_DECOMPRESS_URL=https://download.opensuse.org/tumbleweed/appliances/Aeon-Installer.x86_64.raw.xz
```

### Subsequent runs: Use the downloaded the image

The image was extracted into `/var/lib/openqa/share/factory/hdd/` and we can reuse it:

```
openqa-cli api -X POST isos \
         DISTRI=aeon \
         VERSION=RC3 \
         FLAVOR=IMAGE \
         ARCH=x86_64 \
         NEEDLES_DIR=/var/lib/openqa/tests/opensuse/products/opensuse/needles \
         HDD_1=Aeon-Installer.x86_64.raw
```

# Next steps

1. PR for `https://github.com/os-autoinst/os-autoinst-distri-opensuse` with products/aeon, lib/Distribution, tests/aeon
2. PR for `https://github.com/os-autoinst/os-autoinst-needles-opensuse` to add the Aeon needles
3. PR for `https://github.com/os-autoinst/openQA` to update the `openqa-bootstrap` script

4. Add tests:
    - Check if the default installed apps run
    - Test reboot and shutdown
    - Any other tests to verify system functionality
    - Test updating to a new snapshot (how?)