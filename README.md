<p align="center">
  <a href="https://github.com/MorenoLand/MorenoCore">
    <img src="https://moreno.land/images/morenocore.png" alt="MorenoCore (335a)" width="116px" height="67px">
  </a>
  <h3 align="center">MorenoCore</h3>

  <p align="center">
     Modded TrinityCore 3.3.5a framework with NPC Bots, custom content & OpenSSL 3.x support.<br><br>
     <b>Branches:</b> <code>MorenoCore4</code> (OpenSSL 3.x) | <code>morenocore3</code> (Legacy)<br><br>
  </p>
</p>

## Build Instructions (MorenoCore4 Branch)

```bash
# Install dependencies (Ubuntu 24.04)
apt-get install -y git cmake make gcc g++ libssl-dev libmysqlclient-dev \
                   libreadline-dev zlib1g-dev libbz2-dev libboost-all-dev

# Clone and build
git clone https://github.com/MorenoLand/MorenoCore.git
cd MorenoCore
git checkout MorenoCore4
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/root/Wotlk -DCONF_DIR=/root/Wotlk -DTOOLS=0
make -j$(nproc) authserver worldserver
make install

# Setup configs and run
cd /root/Wotlk
cp authserver.conf.dist authserver.conf
cp worldserver.conf.dist worldserver.conf
# Edit configs with your database credentials, then:
./worldserver
```

**Requirements:** Ubuntu 24.04+, OpenSSL 3.x, MySQL 8.0+, Boost 1.67+

This project is for **personal use** and **learning**. 🤪


