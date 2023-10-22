<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus Apt Git</b></h1>

<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a) ![GitHub last commit (by committer)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc) [![View Apt Repo](https://img.shields.io/badge/Repo%20-%20View%20-%20%23f00e7f?logo=Linux&logoColor=FFFFFF&label=Repo)](https://github.com/Aetherinox/proteus-apt-repo/)

</div>

<br />
<br />

## About
This is the internal part of [Proteus App Manager](https://github.com/Aetherinox/proteus-app-manager) and [Proteus Apt Repo](https://github.com/Aetherinox/proteus-apt-repo).

Once an automatic task is created, every X minutes, the main script of this repo will be called and a list of all Ubuntu packages will be checked, downloaded, and queued for updates (if any available for each package).

Downloaded packages will be locally sent to their correct architecture location:
- incoming/proteus-git/`<codename>`/`<architecture>`

Once the packages are downloaded and placed in the correct location, they will then be added to the apt repo via the package [Reprepro](https://salsa.debian.org/brlink/reprepro), and then finally uploaded to Github.

<br />

---

<br />

## Usage
Download `proteus-git.sh`
```shell
wget "https://raw.githubusercontent.com/Aetherinox/proteus-git/main/proteus-git.sh"
```

Set `proteus-git.sh` to be executable

```shell
sudo chmod +x proteus-git.sh
```

Run the script
```shell
./proteus-git.sh
```

<br />

On first run a `bin` file will be created in `/home/$USER/bin/proteus-git` and another file at `/etc/profile.d/proteus-git.sh`. This allows you to execute the proteus-git app from any folder by using:
```shell
proteus-git
```

You can then delete the original `proteus-git.sh` file you downloaded from Github if you wish.

<br />

---

<br />

## Requirements
Proteus Git has requirements that need met before the script will function. You have a few options below for installing them:

<br />

| Requirement | Desc | Execute |
| --- | --- | --- |
| `apt-url` | <br /> Available from [Proteus Apt Repo](https://github.com/Aetherinox/proteus-apt-repo) <br /> Installing this also installs `apt-move` <br /> <br /> | `sudo apt install apt-url` |
| `apt-move` | <br /> Available from [Proteus Apt Repo](https://github.com/Aetherinox/proteus-apt-repo) <br /> <br />  | `sudo apt install apt-move` |
| `lastversion` | <br /> Python script installed via `pip`. <br /> Info can be viewed on [github page](https://github.com/dvershinin/lastversion) <br /> <br /> | `pip install lastversion` |
| `reprepro` | <br /> Installed via `proteus apt repo`. <br /> Requires `v5.4.2-1` <br /> <br /> | `sudo apt install lastversion` |

<br />

### Install apt-move + apt-url
Add [Proteus Apt Repo]() to your sources.list by first adding the GPG key:
```shell
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
```

Then add the Proteus Apt repo to your list of sources:

```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-apt-repo-archive.list
```

Then update your packages:
```shell
sudo apt update
```

Then install `apt-url`:
```shell
sudo apt install apt-url
```

Both `apt-move` and `apt-url` will be installed. `apt-url` will be placed in `/usr/bin/`

<br />
<br />

### Install apt-move
Install `apt-move` and then manually copy the files in this repo to your machine.
```shell
sudo apt-get install apt-move
```

<br />
<br />

### Install lastversion
Install `pip` and `python3-venv`

```shell
sudo apt install python3-pip
sudo apt-get install python3-venv
```

Download `lastversion` and unzip
```shell
mkdir -p /home/$USER/Packages/lastversion

wget https://github.com/dvershinin/lastversion/archive/refs/tags/v3.3.2.zip

unzip v3.3.2.zip -d /home/aetherinox/Packages/lastversion

cd /home/$USER/Packages/lastversion
```

Install `lastversion`

```shell
pip install lastversion --break-system-packages
```

The `lastversion` bin file will be placed in `/home/$USER/.local/bin`.
We are going to move it to `/home/$USER/bin/`

In terminal, execute
```shell
touch /etc/profile.d/lastversion.sh
```

In the file, add
```
export PATH="$HOME/bin:$PATH"
```

Then refresh the files
```shell
source $HOME/.bashrc
source $HOME/.profile 
```

Log out and back in for changes to take affect.

<br />

---

<br />

## secrets.sh
At the very top of the `proteus-git.sh` file, `secrets.sh` is called. This file is required in order for you to not be rate limited by `lastversion`.

Create a `secrets.sh` and add your `Personal Access Token`.

To create a Personal Access Token for each service, visit:
| Service | Link |
| --- | --- |
| Github | https://github.com/settings/tokens |
| Gitlab | https://gitlab.com/-/profile/personal_access_tokens |

```shell
#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/$USER/bin"
export GITHUB_API_TOKEN=github_pat_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export GITLAB_PA_TOKEN=glpat-xxxxxxxxxxxxxxx
```

<br />

---

<br />

## Proteus Apt Repo
The Proteus Git app is developed to manage the packages associated with the [Proteus Apt Repo](https://github.com/Aetherinox/proteus-apt-repo) and is associated to the [Proteus App Manager](https://github.com/Aetherinox/proteus-app-manager). To utilize the Proteus Apt Repo:

Open Terminal and add the GPG key for the developer to your keyring

```shell
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
```

Then execute the command below to receive our package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-apt-repo-archive.list
```

Finally, run in terminal
```shell
sudo apt update
```
The new repository is now available to use.
