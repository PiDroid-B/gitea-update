# gitea-update

This script send you a notification when a new version of gitea is available. It can update gitea with only one command.

## Menu

1. [How it works](#how-it-works)
2. [Install](#install)
3. [Configure variables](#configure-variables)
4. [Uninstall](#uninstall)
5. [Usage](#usage)
6. [Author, Warning, Licence and Changelog](#author)

## Requirements
- Gitea
- Bash
- mailx

## How it works

This script will be launched manually or through a cron :
- check last version of gitea on github
- check if version is different than current version
  - send you a notification if new version available and option -n (or -c for dry-run)
  - run update if new version available and option -u

## Install

- Install this script where you want (i.e. : /usr/local/bin/gitea-update.sh )  
`cp gitea-update.sh /usr/local/bin/`  
  
- Edit it with the good values in the part VARIABLES (see [Configure variables](#configure-variables))  

- Change rights  
`chmod 700 /usr/local/bin/gitea-update.sh`  
- Add cron for periodic check (i.e. every day at 5am)  
`echo "0 5 * * * root /usr/local/bin/gitea-update.sh -n >/dev/null" > /etc/cron.d/gitea`  

- Check if it works : /usr/local/bin/gitea-update.sh -c  

- No restart needed.

- When new version available, use the option -u as like as the noficitaion suggest

## Configure variables  
go to the 'VARIABLES' part in the script  
  
| key | value | example |
|-|-|-|
| MAIL_FROM | sender | `'Your Mail<your-mail@example.net>'` |
| MAIL_TO | destination | `'<mail@example.net>'` |
| GITEA_PATH | path where gitea is installed | `"/usr/local/bin/"` |
| GITEA_USER | dedicated user for gitea | `"gitea"` |
| CHANGE_LOG_MAX_LINES | max lines of changlog returned in notification | `100` |

## Uninstall
- remove this script (i.e. if installed in suggested path)  
`rm /usr/local/bin/gitea-update.sh`  

- remove cron file 
`rm /etc/cron.d/gitea`

## Usage

```
Usage : ${0##*/} <Option>

Option :
-c : Check (Dry-Run notification)
-n : Notify when update are available
-u : do the update
```

## Author
PiDroid-B, 2019

## Warning

Use it at your own risk. The author assumes no responsibility for all usage or error that result from this script.

## Licence
This project is licensed under the GPL v3 License. See the [LICENSE](https://github.com/PiDroid-B/gitea-update/blob/master/LICENSE) file for the full license text.

## Changelog

| version | release | date | description |
|-|-|-|-|
| 1.0.0 |  | 2019-08-24 | Init |


