## Installation of system requirements
```
apt-get install -y curl gnupg bzip2 && \
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
apt-get install -y nodejs && \
npm install -g backstopjs --unsafe-perm
```
Google Chrome
```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install
```
