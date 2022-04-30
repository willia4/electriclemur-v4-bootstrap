# Readme

This is the bootstrapper for the electriclemur.org suite of websites. 

It will provision a server in Digital Ocean and configure it for hosting sites. 

## Prerequisites 

- [jq](https://stedolan.github.io/jq/)
- [curl](https://curl.se/)
- a `secrets.json` file based on the model of `secrets.template.json`
- at least one SSH key associated with your Digital Ocean account. The user running the script must be able to use this key via a bare `ssh` command. This SSH key must be added to the `droplet_ssh_keys` array in `secrets.json`.
- a domain name configured in Digital Ocean; some record in this domain (from `secrets.json`) will be configured as an A record pointing to the created server

## Notes

If you have more than 200 SSH keys in your Digital Ocean account, this script may not be able to add your keys (if they are not on the first page).