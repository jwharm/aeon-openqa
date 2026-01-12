# Instructions to setup and run Aeon openQA tests

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

Copy the files `templates` and `main.pm` and the complete `needles` directory from the `products/aeon` directory in this repo to the directory `/var/lib/openqa/tests/opensuse/products/aeon` that you just created.

* **TODO:** The needles are in a separate directory for now, but I want to change this into a symlink to the opensuse needles, and add the aeon needles there.

Run the `templates` script. It is a shell script, so you can execute "`./templates`" and it will add the definitions to the openQA database.

Change the owner of the needles directory. This is required to save changes in the needle editor of the openQA web UI:

```
sudo chown -R geekotest:geekotest /var/lib/openqa/tests/opensuse/products/aeon/needles
```

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

Copy `installer.pm` and `firstboot.pm` into this directory. These scripts contain the actual tests, and are called from the `main.pm` script we copied earlier.

Finally, create an `aeon` symlink to osado. A similar link is already present for `sle`.

```
sudo ln -s opensuse /var/lib/openqa/share/tests/aeon
```

## Run the tests

### Option 1: Manually download the image

Download the `Aeon-Installer.x86_64.raw.xz`, extract it, and copy the `.raw` file into `/var/lib/openqa/share/factory/hdd/`. (Do NOT copy it into `/iso`, that doesn't work.)

Run the tests:

```
openqa-cli api -X POST isos \
         DISTRI=aeon \
         VERSION=RC3 \
         FLAVOR=DVD \
         ARCH=x86_64 \
         HDD_1=Aeon-Installer.x86_64.raw
```

### Option 2: Automatically download the image

To start a test with the online hosted installer image, we must first allow `opensuse.org` as a safe domain in `openqa.ini`:

* Copy `etc/01-enable-download.ini` into `/etc/openqa/openqa.ini.d/`
* Run `sudo systemctl restart openqa-gru openqa-worker@1 openqa-webui` to load the new config

Run the test, same as above, but use the `HDD_1_DECOMPRESS_URL` argument to download and decompress the image:

```
openqa-cli api -X POST isos \
         DISTRI=aeon \
         VERSION=RC3 \
         FLAVOR=DVD \
         ARCH=x86_64 \
         HDD_1_DECOMPRESS_URL=https://download.opensuse.org/tumbleweed/appliances/Aeon-Installer.x86_64.raw.xz
```
