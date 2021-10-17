# Raspi Cluster

This repo contains instructions to set up a cluster of Raspberry Pi's running Kubernetes with k3s ([k3s-ansible]),
and a monitoring stack with grafana + prometheus ([cluster-monitoring]).

This was inspired by [Jeff Geerling's youtube series].

# Getting started

Running ansible directly on a Mac can bring some problems with dependencies, so it is recommended to use the Docker container provided (this is already used in the scripts).

## 1 - Flashing the SD cards
1. Add the required env variables to the `.env` file
```sh
COUNTRY="Your countrie's 2 letter ISO code"
NETWORK_SSID="Your WiFi SSID"
NETWORK_PASSWORD="Your WiFi pass"
EMAIL="your@email.com"
```
1. (Repeat for each SD card) Connect the SD cards to the computer and run the script to flash them (update the global variables if you want a different OS version):
    ```sh
    ./01-flash-ds-cards.sh
    ```

## 2 - Setting up the OS
1. Turn on the Raspberry Pi's after inserting the SD cards into them
1. Get the IP addresses of the Raspberry Pi's (you can use `nmap -sn 192.168.1.0/24` with your corresponding network CIDR)
1. (Optional) Verify that everything works as expected by connecting to each of the IP addresses using the default user `pi` and password `raspberry`
1. Add the IP addresses at the bottom of the `.env` file (you can choose a different node for the ingress):
    ```sh
    RASPI_MASTER_IP="RASPI_MASTER_IP"
    RASPI_WORKER_IPS=(
        "RASPI_WORKER_1_IP"
        "RASPI_WORKER_2_IP"
        "RASPI_WORKER_3_IP"
    )
    INGRESS_IP=${RASPI_WORKER_IPS[@]:0:1}
    ```
1. Run the setup script, which runs the ansible playbooks using the docker container (it will prompt for a new password):
    ```sh
    ./02-setup-pi-cluster.sh
    ```

## 3 - Installing kubernetes (k3s) in the cluster
1. Add the desired kubeconfig file at the bottom of the `.env` file:
    ```sh
    KUBECONFIG="${HOME}/.kube/config_rpi"
    ```
1. Run the setup script which clones the [k3s-ansible] repo:
    ```sh
    ./03-install-k3s.sh
    ```
1. Access the ingress endpoints for `grafana` (also available for `prometheus` and `alertmanager`) at the address below, using the default `admin` user and pass (you'll be prompted to change it):
    ```sh
    open -a "Google Chrome" "https://grafana.${INGRESS_IP}.nip.io"
    ```

# Useful commands
This project uses a docker container to run ansible commands. You can execute commands in the cluster by first setting up the docker container with `docker compose` (you might have it running from the setup):
```sh
source commons.sh
docker_compose_up # This function is defined in the commons.sh file
```

Then you can run ansible modules or commands in the cluster, either in the whole cluster on individual groups or hosts by using `exec_in_docker <docker_compose_service_name> <command>`:
```sh
exec_in_docker ansible raspi_cluster -m ping
exec_in_docker ansible raspi-master -a "free -h"
exec_in_docker ansible raspi_workers -a "df -h"
exec_in_docker ansible raspi-worker-01 -a "ifconfig"
```

You can also reboot the cluster and wait for it to come up with:
```sh
reboot_and_wait
```

Or just ping the hosts until they are all up (this refers to the actual raspberry pi's, not the k8s nodes):
```sh
wait_for_cluster
```

## Shutting down the cluster and docker containers
Just run the `shutdown-cluster.sh` script.

# Hardware

Note that fans are recommended. In my case the temperature of the idle cluster running the monitoring stack was ~50°C without fan vs ~30°C with fan.

## Essentials
| Part | Quantity | Unit price | Sub total |
|------|:-------:|-----------:|----------:|
|[Gigastone 64GB SD card](https://www.amazon.co.uk/gp/product/B07P18ZSCM/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1) | Pack of 5 | - | £39.98 |
|[Raspberry Pi 4 (4GB)](https://thepihut.com/products/raspberry-pi-4-model-b?variant=20064052740158) ([amazon](https://www.amazon.co.uk/gp/product/B07TC2BK1X/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1)) | 4 | £54.00 | £216.00
|[GeekPi case with coolers](https://www.amazon.co.uk/gp/product/B07MW24S61/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1) | 1 | £17.00 | £17.00 |
| [40W 5-Port 8A USB Charger](https://www.amazon.co.uk/gp/product/B0101VYYRM/ref=ppx_od_dt_b_asin_title_s00?ie=UTF8&psc=1) | 1|£20.99 | £20.99|
| [USB C Cable 0.3m](https://www.amazon.co.uk/gp/product/B07X31LJZG/ref=ppx_yo_dt_b_asin_title_o01_s00?ie=UTF8&th=1) | 2 pack of 2 | £6.98 | £13.96|
|**Total** | | | **£307.93** |

## Optional parts
| Part | Quantity | Unit price | Sub total |
|------|:-------:|-----------:|----------:|
|[Lan Cable 0.3m](https://www.amazon.co.uk/gp/product/B00H7CPYIM/ref=ppx_yo_dt_b_asin_title_o01_s01?ie=UTF8&psc=1)| 4|£2.99 | £11.96|
|[5 Port Gigabit Ethernet unmanaged switch](https://www.amazon.co.uk/gp/product/B00AYRZYG4/ref=ppx_yo_dt_b_asin_title_o01_s02?ie=UTF8&th=1) | 1 | £11.49 |£11.49|
|[1 TB Portable USB 3.2 external HD](https://www.amazon.co.uk/gp/product/B07997KKSK/ref=ppx_yo_dt_b_asin_title_o01_s01?ie=UTF8&th=1) | 1 | £38.00 | £38.00 |
|**Total** | | | **£61.45** |

**Grand total: £368.91**

# Next steps
- Configure a VPN
- Add a pi hole with DNS in the cluster
- Add a load balancer to access it from the public internet


<!--References-->

[Jeff Geerling's youtube series]: https://www.youtube.com/playlist?list=PL2_OBreMn7Frk57NLmLheAaSSpJLLL90G
[k3s-ansible]: https://github.com/k3s-io/k3s-ansible
[cluster-monitoring]: https://github.com/carlosedp/cluster-monitoring