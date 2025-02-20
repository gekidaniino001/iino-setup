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
wget -O /tmp/amd64.env https://raw.githubusercontent.com/autowarefoundation/autoware/main/amd64.env && source /tmp/amd64.env

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
  python3-usb \
  python3-serial

#
# Install iinomob2.autoware
#
sudo chown $(whoami) ~/.ssh/id_rsa
sudo chmod 600 ~/.ssh/id_rsa
cd ~
git clone git@github.com:gekidaniino001/iinomob2.autoware
cd ~/iinomob2.autoware
bash install.sh
