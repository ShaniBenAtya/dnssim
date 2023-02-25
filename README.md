
# DNS Simulator

  

In this guide, we’ll learn the basic things needed in order to use “DNS-FullProtocolSimulator”.

  

“DNS-FullProtocolSimulator” is a testing environment which simulates all parts of any open-source DNS implementation and allows researchers to debug and test the protocol from end to end.

  

“DNS-FullProtocolSimulator” was created by me, **Shani Stajnrod**, as part of my thesis research. Feel free to contact me for any help via [shaaniba93@gmail.com](mailto:shaaniba93@gmail.com).

If the code or data help you, please cite the following paper:

````

@inproceedings{NRDelegationAttack,
  title={QuoteR: NRDelegationAttack: Complexity DDoS attack on DNS Recursive Resolvers},
  author={Qi, Yehuda Afek, Anat Bremler-Barr and Shani Stajnrod},
  year={2023}
}

````

## Docker Usage

If you are unfamiliar with Docker I suggest to first read about Docker here: [https://docs.docker.com/get-started/](https://docs.docker.com/get-started/)

  

1. Download the docker from Docker Hub `docker pull shanist/dnssim:latest`

2. Run the docker interactively so you can control the environment `docker container run --dns 127.0.0.1 -it dnssim /bin/bash` (It is important to use –dns 127.0.0.1 flag so the environment DNS will be local. **Changing resolv.conf inside a Docker won’t work**)

3. Now you will have a terminal inside the environment.

4. In order to open another terminal for the environment first run `docker container ls`, look for “dnssim” docker name and copy the Docker ID ![alt text](https://github.com/ShaniBenAtya/dnssim/blob/master/images/dockercontainerls.png) Run `docker exec -it <CONTAINER_ID> bash`
5. To open more terminals into the environment, repeat step 4

**Remember to run `resolver` and `authoritative` you must open more than one terminal for you environment**

## Getting to know the environment
“DNS-FullProtocolSimulator”, like the DNS protocol, has three main parts: Client, Resolver (which is currently an implementation of bind9) and a chain of authoritative servers (currently including root server and TLD which are implemented with NSD).

### Resolver

To use the DNS protocol in a closed testing environment, I changed Bind9 implementation and directed it to use my root as the default and only root server. This is done by changing the following the `root_ns[]` list in `rootns.c` file.

Also, in order to follow the code conveniently via debugging, code optimization was disabled in the compiler and the number of threads was limited. This was done by changing the `main.c` number of CPU’s as follows:

-   `result = isc_taskmgr_create(named_g_mctx, `**`named_g_cpus`**`, 0, named_g_nm, &named_g_taskmgr);`
    

Was changed to:

-   `result = isc_taskmgr_create(named_g_mctx, `**`1`**`, 0, named_g_nm, &named_g_taskmgr);`
    

### Authoritative servers

Our authoritative servers are implemented using NSD.

Currently, we have two authoritative servers in the environment: root server and a TLD which zone is “home.lan”. In the next chapter, we’ll discuss how to configure them.

## Configuration –

**Environment IP address:**

-   `127.0.0.1` – Client
    
-   `127.0.0.1` – Our own Resolver (Yeah, they have the same IP but that’s ok)
    
-   `127.0.0.2` – Root authoritative
    
-   `127.0.0.200` – “home.lan” TLD authoritative
    
-   `127.0.0.53` – The default resolver – **DO NOT USE IT WHILE TESTING**
    

**Authoritative Servers:**

Our authoritative servers are located at `/env/nsd_root` and `/env/nsd_attack`. To use them, you’ll first want to configure their zone files which are located inside their folder and called `“ZONE_NAME.forword”`. You can add any configuration you want to the zone file and restart it to apply the changes.

**Resolver:**

First, go to the resolver implementation folder (We have both `Bind-9.16.6` (Which is non-vulnerable to NXNS).
You can easily replace the `Bind9` version by going to `/env/bind9` and use `git checkout` for a different branch. (e.g. bind-9.16.2, Which is vulnerable to NXNS) 

>**NOTE:** The environment is pre-installed with `Bind 9.16.6` so you can skip the next step if you don't want a different verion.

Now, while inside Bind9 folder follow run the following commands:

<! -- 1. `autoreconf -fi` -->
1. `./configure`
2. `make -j4`
3. `make install`
    

> **NOTE:** In order to change resolv.conf (Default resolver of the environment) look at “Docker Usage” step 2.

## Turning on all parts of the environment

Starting the environment is done by:

[Open three terminal in the Docker](#docker-usage)

-   First, turn on the Resolver:
    
    -   `cd /etc` **(IMPORTANT!!)**
        
    -  `named -g -c /etc/named.conf`
        
    -   If there is a key-error run `rndc-confgen -a` and try to start it again
        
    -   If you’re getting the following error: `“loading configuration: Permission denied”`, use the following fix:
        
        -   `chmod 777 /usr/local/etc/rndc.key`
            
        -   `chmod 777 /usr/local/etc/bind.keys`
            
-   Now, turn on the Authoritative servers in a different environment terminal:
    
    -   Navigate to the Authoritative server folder (`/env/nsd_attack` and `/env/nsd_root`), then run: `nsd -c nsd.conf -d -f nsd.db`
        
    -   If there is an error stating that the port is already in use, run - `service nsd stop` and try to start it again
        

> **YAY! YOU ARE READY TO START TESTING!!!**

## Useful commands –

-   Bind’s configuration file - `/etc/named.conf`
    
-   Cache –
    
    -   To flush the cache(The resolver should be up) –
        
        -   `rndc flush`
            
        -   `rndc reload`
            
    -   To show the current cache –
        
        -   `rndc dumpdb -cache`
            
        -   cached DB location: `/etc/bind/named_dump.db`
            

## Useful tools in the environment for you to use –

“DNS-FullProtocolSimulator” already has the following useful testing tools:

-   Wireshark
	- `docker exec -ti <container id> cat /sys/class/net/eth0/iflink`
	- `ip link | grep <output from previous command>`
	- `<output from first command>`: `<name of the interface>`
	- you can also use the following tutorial: https://github.com/nicolaka/netshoot

-   Resperf:
    
    -   Send queries to the resolver in order to calculate the server maximum throughput and its latency
        
        -   `resperf -d INPUT_FILE -s 127.0.0.1 -v`
            
    -   In order to use resperf with constant range of queries per second:
        
        -   `Resperf-report -d INPUT_FILE -s SERVER_IP -v -m 500 -c 60 -r 0`
            
        -   Where: `-m` is the number of QPS that will be sent, `-c` is the time in which resperf will try to send the queries, and `-r` is the time resperf will have an ramp-up phase before sending the packets in a constant time, we’ll want the ramp-up to be zero.
            
-   Valgrind and kcachegrind:
    
    -   Turn on the resolver with the valgrind tool:
        
        -   `valgrind --tool=callgrind named -g -c /etc/named.conf`
            
    -   After finishing the test, open the file in kcachegrind:
        
        -   `kcachegrind OUTPUT_FILE`
            
-   psrecord: `psrecord <pid of bind9> --interval 1 --plot OUTPUT_FILE.png`
	- > **NOTE:** to find Bind9 PID use `ps aux | grep named`

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.


## Contact

<!-- Shan - [@your_twitter](https://twitter.com/your_username) - email@example.com -->

DNS Simulator: [https://github.com/ShaniBenAtya/dnssim](https://github.com/ShaniBenAtya/dnssim)

## Contribution
Bug reports and pull requests are welcome on GitHub at https://github.com/ShaniBenAtya/dnssim. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

### Building the Docker
`docker build -t dnssim .`

> **NOTE:** make sure the submodules have been downloaded (Check that bind9 and nsd folder aren't empty), if they are, run `git submodule update --init`

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

