FROM  ubuntu:18.04

# RUN apt-get -y install make
# CMD ["apt-get" ,"hello world"]
RUN apt-get update && apt-get install -y apt-utils make gcc pkg-config python3 python3-pip python-ply libuv1-dev libuv1 python3-pytest openssl libcap-dev libssl-dev libevent-dev flex bison software-properties-common dh-autoreconf libnghttp2-dev nano vim git tcpdump net-tools iputils-ping

# RUN curl https://bootstrap.pypa.io/get-pip.py | python

RUN pip3 install --upgrade pip

RUN pip3 install --upgrade setuptools

COPY requirements.txt /tmp

COPY reproduction /env/reproduction

WORKDIR "/tmp"
RUN pip3 install -r requirements.txt

# WORKDIR "/env"
COPY bind9 /env/bind9_16_6
# # RUN 'wget https://github.com/ShaniBenAtya/bind9/archive/refs/heads/9_16_6.zip'
WORKDIR "/env/bind9_16_6"
#RUN autoreconf -fi
RUN ./configure
RUN make -j4
RUN make install

COPY bind9_16_2 /env/bind9_16_2
WORKDIR "/env/bind9_16_2"
#RUN autoreconf -fi
RUN ./configure
RUN make -j4

COPY bind9_16_33 /env/bind9_16_33
WORKDIR "/env/bind9_16_33"
#RUN autoreconf -fi
RUN ./configure
RUN make -j4

WORKDIR "/etc"
#RUN rndc-confgen -a
#RUN chmod 777 /usr/local/etc/rndc.key
#RUN chmod 777 /usr/local/etc/bind.keys

COPY nsd /env/nsd
WORKDIR "/env/nsd"
RUN aclocal && autoconf && autoheader
RUN ./configure --enable-root-server
RUN make -j4
RUN make install

COPY nsd_attack /env/nsd_attack
COPY nsd_root /env/nsd_root
RUN useradd nsd
RUN chmod 777 /env/nsd_root/nsd.db
RUN chmod 777 /env/nsd_attack/nsd.db

RUN add-apt-repository ppa:dns-oarc/dnsperf && apt-get update
RUN apt-get install -y resperf dnsperf valgrind

COPY named.conf /etc/named.conf

WORKDIR "/env"
