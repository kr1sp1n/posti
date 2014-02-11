posti
=====

Simple IMAP for the terminal and tmux.
Just to see if I received any new mails in my inbox.


## Install

```bash
git clone git@github.com:kr1sp1n/posti.git
npm install -g
```

## Usage
It will check your INBOX every 5 seconds for 'UNSEEN' messages.

```bash
posti -u youremail@gmail.com -p yourpassword -h imap.gmail.com
```

__OUTPUT__

```bash
INBOX

FROM             SUBJECT                                          WHEN
Gmail Team       Welcome to the new Gmail inbox                   4 hours ago
Krispin          TEST posti                                       3 hours ago
STRATO           Jetzt zuschlagen: Weitere neue Top-Level-Domain  24 minutes ago
```

New emails will be added at the end of the list.
