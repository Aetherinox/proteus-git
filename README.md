<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus Apt Git</b></h1>

<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a) ![GitHub last commit (by committer)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc) [![View Apt Repo](https://img.shields.io/badge/Repo%20-%20View%20-%20%23f00e7f?logo=Linux&logoColor=FFFFFF&label=Repo)](https://github.com/Aetherinox/proteus-apt-repo/)

</div>

<br />
<br />

## About
This is an internal part of the [Proteus App Manager](https://github.com/Aetherinox/proteus-app-manager) system which allows for defined packages to be automatically checked and new versions to be downloaded to the appropriate folders, which is then sent over to the repo server to be uploaded.

<br />

---

<br />

## Usage
Download the `proteus-git.sh`.
```shell
wget "https://raw.githubusercontent.com/Aetherinox/proteus-git/main/proteus-git.sh"
```

Set the `proteus-git.sh` to be executable

```shell
sudo chmod +x setup.sh
```

Then run the script:
```shell
./proteus-git.sh
```

<br />

Once the script is ran for the first time, a `bin` file will be created in `/home/$USER/bin/proteus-git` and another file in `/etc/profile.d/proteus-git.sh`. This allows you to execute the proteus git app from any folder via:
```shell
proteus-git
```

You can then delete the original `proteus-git.sh` file you downloaded from Github if you wish.

<br />

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
