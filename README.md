Note: the tool is still in progress and not production ready.

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

## How to start?

1. Go to application directory.
2. Prepare tests structure with:
```
make_structure()
```
3. Define new scenario with provided label:
```
define_scenario("load-app")
```
You can leave the template that tests ready application screen or create your own one.
To make it simpler you can use: 
https://chrome.google.com/webstore/detail/puppeteer-recorder/djeegiggegleadkkbgopoonhjimgehda

4. Create test scenario:
```
run_scenario("load-app", action = "reference")
```

5. Perform test:
```
run_scenario("load-app")
```
