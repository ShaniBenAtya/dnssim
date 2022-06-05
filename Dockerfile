FROM  ubuntu:18.04

# RUN apt-get -y install make
# CMD ["apt-get" ,"hello world"]
RUN apt-get update && apt-get install -y apt-utils make gcc pkg-config python3 python3-pip python-ply libuv1-dev libuv1 python3-pytest openssl libcap-dev libssl-dev libevent-dev flex bison software-properties-common


# RUN curl https://bootstrap.pypa.io/get-pip.py | python

RUN pip3 install --upgrade pip

RUN pip3 install --upgrade setuptools

COPY requirements.txt /tmp

WORKDIR "/tmp"
RUN pip3 install -r requirements.txt

# WORKDIR "/env"
COPY bind9 /env/bind9
# # RUN 'wget https://github.com/ShaniBenAtya/bind9/archive/refs/heads/9_16_6.zip'
WORKDIR "/env/bind9"
RUN ./configure
RUN make -j4
RUN make install

WORKDIR "/etc"
RUN rndc-confgen -a
RUN chmod 777 /usr/local/etc/rndc.key
RUN chmod 777 /usr/local/etc/bind.keys

COPY nsd-4.3.3 /env/nsd
WORKDIR "/env/nsd"
RUN ./configure --enable-root-server
RUN make -j4
RUN make install

COPY nsd_attack /env/nsd_attack
COPY nsd_root /env/nsd_root

RUN add-apt-repository ppa:dns-oarc/dnsperf && apt-get update
RUN apt-get install -y resperf dnsperf valgrind

WORKDIR "/env"