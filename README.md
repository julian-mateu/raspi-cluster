# Raspi Cluster

This repo contains instructions to set up a cluster of Raspberry Pi's running Kubernetes with k3s ([k3s-ansible]),
and a monitoring stack with grafana + prometheus ([cluster-monitoring]).

This was inspired by [Jeff Geerling's youtube series].

# Getting started

Running ansible directly on a Mac can bring some problems with dependencies, so it is recommended to use the Docker container provided (this is already used in the scripts).

## 1 - Flashing the SD cards
1. Add the required env variables to the `.env` file
```sh
COUNTRY="Your country's 2 letter ISO code"
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

## 4- (Optional) Setting up NFS with an external hard drive
1. Connect the hard drive to the master node (using the usb 3.0 blue port).
1. Run the setup disk script which will run `fdisk -l` and prompt you for the device name:
    ```sh
    05-setup-nfs-disk.sh
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
- How to access it from the external world? (Especially if your ISP has a NAT as is my case) - see the [investigations](./spikes):
    - **~~[Dataplicity](https://www.dataplicity.com/devices)~~** -> Did not work
    - **~~[localtunnel](https://github.com/localtunnel/localtunnel)~~** -> Works for HTTP/TCP but not for UDP, so I could not use the VPN (Or I would have to make adjustments to it)
    - **~~[ngrok](https://ngrok.com/)~~**: ([article](https://medium.com/oracledevs/expose-docker-container-services-on-the-internet-using-the-ngrok-docker-image-3f1ea0f9c47a)) -> Works, but I can only have 1 tunnel active at the time in the free version, and I don't think I can use UDP for free.
    - NOTE: the previous 2 options could work using something like [nginx for TCP and UDP](https://docs.nginx.com/nginx/admin-guide/load-balancer/tcp-udp-load-balancer/)
    Another solution could be configure the VPN to use TCP, and run a load balancer that routes traffic to the VPN and other servers (I'm not sure if this could be done based on the path or some other criteria)
    - **full host** in something like AWS EC2 (free tier for 1 year, which is not terrible if the setup can be automated): -> As the ideal setup is both a public VPN server and a public website (which can access anything if it is the load balancer), I believe this is the only feasable option given the above research, which runs both the VPN server and the load balancer.
- Improve host security ([ssh config](https://cryptsus.com/blog/how-to-secure-your-ssh-server-with-public-key-elliptic-curve-ed25519-crypto.html), firewall, etc), eg 
- Domain name (Freenom needs to be used from the country that created the account. It does not work together with cloudflare. It's probably better to pay for a cheap domain name)
- Reverse proxy in Nginx (with HTTPS) -> EC2
    - Add a load balancer to access it from the public internet
        - [Setup Nginx Proxy Manager](https://www.youtube.com/watch?v=P3imFC7GSr0)
        - [Secure Nginx Proxy Manager](https://www.youtube.com/watch?v=UfCkwlPIozw)
        - [Access lists for Nginx Proxy Manager](https://www.youtube.com/watch?v=G9voYZejH48)
    - [Get a wildcard cert](https://www.youtube.com/watch?v=TBGOJA27m_0)
- Configure a VPN -> EC2
- Others from [this blog](https://greg.jeanmart.me/2020/04/13/deploy-nextcloud-on-kuberbetes--the-self-hos/)
    - Add a pi hole with DNS in the cluster
    - set up a NAS (from the blog, also [this video](https://www.youtube.com/watch?v=gyMpI8csWis))
- Use Vault to setup a KPI (manage certificates, secrets, etc)
- email server? (google business domain and also free drive for backup)
- RAID 1 disk with cheap usb controllers (See [Rpi NAS with RAID](https://www.jeffgeerling.com/blog/2020/building-fastest-raspberry-pi-nas-sata-raid))
- Automated backups
    - NAS
    - AWS S3 Glacier


<!--References-->

[Jeff Geerling's youtube series]: https://www.youtube.com/playlist?list=PL2_OBreMn7Frk57NLmLheAaSSpJLLL90G
[k3s-ansible]: https://github.com/k3s-io/k3s-ansible
[cluster-monitoring]: https://github.com/carlosedp/cluster-monitoring