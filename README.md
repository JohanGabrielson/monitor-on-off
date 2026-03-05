## Monitor Mode Switcher (Alpha Adapter)

* Check which mode the adapter is on
* switch between monitor mode and managed mode
* stop interfering processes
* restart network services
* change MAC address

### Installation

~~~
git clone https://github.com/JohanGabrielson/monitor-on-off.git
cd monitor-on-off
chmod +x monitor-on-off.sh
~~~

### Usage
~~~
./monitor-on-off.sh
~~~

The script starts an interactive menu where the user can:
* switch monitor mode  on/off 
* show status
* randomize MAC address

### Requirements
* Linux
* Alfa adapter
* airmon-ng

### Known limitations
* The script is built for Alfa adapters, might need adjustments for other network cards
* requires root access


### License
Free to use and modify at your own risk

(README is to be continued)
