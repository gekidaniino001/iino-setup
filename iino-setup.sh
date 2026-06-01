#!/bin/bash
set -ex

#
# init
#
sudo apt update
sudo apt install -y openssh-server emacs nkf git

#
# ROS2
#
sudo apt install -y curl gnupg lsb-release
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install -y ros-humble-desktop
if ! egrep "^source /opt/ros/humble/setup.bash" $HOME/.bashrc > /dev/null; then
  echo ""
  echo "export ROS_LOCALHOST_ONLY=1" >> ~/.bashrc
  echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
fi
source ~/.bashrc

#
# colcon, gazebo, rqt
#
sudo apt install -y \
  python3-colcon-common-extensions \
  gazebo \
  ros-humble-gazebo-* \
  ros-humble-rqt-*

#
# Dev Tools
#
sudo apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  ros-dev-tools \
  python3-flake8-blind-except \
  python3-flake8-builtins \
  python3-flake8-class-newline \
  python3-flake8-comprehensions \
  python3-flake8-deprecated \
  python3-flake8-import-order \
  python3-flake8-quotes \
  python3-pytest-repeat \
  python3-pytest-rerunfailures  

#
# rosdep
#
sudo apt update
[[ -e /etc/ros/rosdep/sources.list.d/20-default.list ]] && sudo rm /etc/ros/rosdep/sources.list.d/20-default.list
sudo rosdep init
rosdep update

#
# RMW Implementation
#
## wget -O /tmp/amd64.env https://raw.githubusercontent.com/autowarefoundation/autoware/main/amd64.env && source /tmp/amd64.env
## URL not found 2026/05
rmw_implementation=rmw_cyclonedds_cpp
ROS_DISTRO=humble
rosdistro=$ROS_DISTRO

# For details: https://docs.ros.org/en/humble/How-To-Guides/Working-with-multiple-RMW-implementations.html
rmw_implementation_dashed=$(eval sed -e "s/_/-/g" <<< "${rmw_implementation}")
sudo apt install -y ros-${rosdistro}-${rmw_implementation_dashed}

# (Optional) You set the default RMW implementation in the ~/.bashrc file.
if ! egrep "^export RMW_IMPLEMENTATION=${rmw_implementation}" ~/.bashrc > /dev/null; then
  echo '' >> ~/.bashrc
  echo "export RMW_IMPLEMENTATION=${rmw_implementation}" >> ~/.bashrc
fi

#
# pacmod
#
wget -O /tmp/amd64.env https://raw.githubusercontent.com/autowarefoundation/autoware/main/amd64.env && source /tmp/amd64.env

# Taken from https://github.com/astuff/pacmod3#installation
sudo apt install -y apt-transport-https
sudo sh -c 'echo "deb [trusted=yes] https://s3.amazonaws.com/autonomoustuff-repo/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/autonomoustuff-public.list'
sudo apt update
sudo apt install -y ros-${rosdistro}-pacmod3

#
# Autoware Core dependencies
#
pip3 install gdown

#
# Autoware Universe dependencies
#
sudo apt install -y geographiclib-tools
sudo geographiclib-get-geoids egm2008-1

#
# pre-commit dependencies
#
clang_format_version=16.0.0
pip3 install pre-commit clang-format==${clang_format_version}
sudo apt install -y golang

#
# Additional packages
#
sudo apt install -y \
  ros-humble-rt-usb-9axisimu-driver \
  ros-humble-urg-node \
  ethtool \
  linuxptp \
  net-tools \
  python3-evdev \
  python3-shapely \
  python3-usb \
  python3-serial

pip3 install google-api-python-client google-auth-httplib2 google-auth-oauthlib
pip3 install pydantic

pip3 install --upgrade requests urllib3
pip3 install pydantic pygame

#
# User Group
#
sudo usermod -aG dialout gekidaniino
sudo usermod -aG input gekidaniino

#
# Auto boot (enabled=false)
#
auto_dir=~/.config/autostart
[[ -e ${auto_dir} ]] || mkdir -p ${auto_dir}

auto_path=${auto_dir}/auto_boot.sh.desktop
[[ -e ${auto_path} ]] || cat >${auto_path} <<EOF
[Desktop Entry]
Type=Application
Exec=/home/gekidaniino/iinomob2.autoware/src/iino.universe/boot_scripts/auto_boot.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=false
Name[ja_JP]=iino
Name=iino
Comment[ja_JP]=
Comment=
EOF

#
# keyboad no caps
#
kbd_path=/etc/default/keyboard
if grep '^XKBOPTIONS=""' ${kbd_path} >/dev/null; then
  [[ -e ${kbd_path}.0 ]] || sudo cp -p ${kbd_path} ${kbd_path}.0
  sudo sed -i 's/^XKBOPTIONS=""/XKBOPTIONS="ctrl:nocaps"/' ${kbd_path}
fi

#
# Alias
#
[[ -e ~/.bash_aliases ]] || cat > ~/.bash_aliases <<EOF
alias iinogui='~/iinomob2.autoware/src/iino.universe/boot_scripts/gui.sh'
alias iinokill='~/iinomob2.autoware/src/iino.universe/boot_scripts/iino_kill.sh'
alias ccb='colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'
alias ccbbp='colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --base-paths '
alias ccbp='colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-select'
alias 3_bash='. ~/iinomob2.autoware/src/iino.universe/boot_scripts/setup.bash'
alias iinocd='cd ~/iinomob2.autoware/src/iino.universe'
alias scd='cd ~/iinomob2.autoware/src/iino.scenario'
alias rriino='ros2 run iino_common'
alias rviztest='rviz2 -d ~/iinomob2.autoware/src/iino.universe/launcher/iino_aw_launch/rviz/test.rviz'
alias camera_data_get='~/iinomob2.autoware/src/iino.universe/tool/get_raspberrypi_data.sh'
source ~/ros2-aliases/ros2_simple_aliases.bash
EOF

#
# Install iinomob2.autoware
#
sudo chown $(whoami) ~/.ssh/id_rsa
sudo chmod 600 ~/.ssh/id_rsa
cd ~
git clone git@github.com:gekidaniino001/iinomob2.autoware
cd ~/iinomob2.autoware

PKG="setuptools"
VER_TGT="59.6.0"
VER_NOW=$( pip show $PKG | grep Version | tr -d ' ' | cut -d : -f2 )
if [ "$VER_NOW" != "$VER_TGT" ]; then
  pip install $PKG==$VER_TGT >/dev/null
fi


patch -p1 <<EOF
--- a/install.sh
+++ b/install.sh
@@ -18,7 +18,7 @@ rosdep update
 
 rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO
 
-colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
+colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --parallel-workers 4
 
 pushd src/iino.universe/tool
 ./inst_wx.py
EOF


bash install.sh

source src/iino.universe/boot_scripts/setup.bash

$TOOL_DIR/lan_setup.py
$TOOL_DIR/ssd_setup.py
