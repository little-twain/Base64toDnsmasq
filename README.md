# Base64toDnsmasq

A shell script which convert base64 domain list into dnsmasq rules.

This script relys on `sed`, `coreutils-base64`, `aria2`, `libopenssl1.1`, `ca-bundle`.

## Usage

``` plaintext
Valid options are:
    -d <DNS_IP>
                DNS IP for the Base64 Domain List
    -p <DNS_PORT>
                DNS Port for the Base64 Domain List
    -s <IPSET_NAME>
                Ipset name for the Base64 Domain List
    -o <OUT_FILE>
                Path to the output dnsmasq file
    -l <EXTRA_DOMAIN_FILE>
                Add other domain to the Base64 Domain List
    -url <BASE_URL>
                Custom url for Base64 Domain List
```

Default Base64 Domain List from [GFWList](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt).