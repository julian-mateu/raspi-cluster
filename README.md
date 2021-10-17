# Raspi Cluster

This repo contains instructions to set up a cluster of Raspberry Pi's running k8s.

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
1. Add the IP addresses at the bottom of the `.env` file:
    ```sh
    RASPI_MASTER_IP="RASPI_MASTER_IP"
    RASPI_WORKER_IPS=(
        "RASPI_WORKER_1_IP"
        "RASPI_WORKER_2_IP"
        "RASPI_WORKER_3_IP"
    )
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

[k3s-ansible]: https://github.com/k3s-io/k3s-ansible