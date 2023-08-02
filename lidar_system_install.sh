#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check ROS version
setup_script="/opt/ros/noetic/setup.bash"
if [[ -f "$setup_script" ]]; then
    source "$setup_script"
    rosversion=$(rosversion -d)
    echo "ROS version: $rosversion"
else
    echo "ROS Noetic not installed, installing now"
fi

# Install ROS Noetic
if [[ "$rosversion" != "noetic" ]]; then
    # Setup your sources.list
    sudo echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list

    # Setup your keys
    sudo apt install curl
    sudo curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

    # Update package index
    sudo apt update

    # Install ROS
    sudo apt install ros-noetic-desktop-full

    # Add aliases to bash
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
    source ~/.bashrc

    # Install dependencies for building packages
    sudo apt install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
    sudo apt install python3-rosdep
    sudo rosdep init
    rosdep update
else
    echo "ROS Noetic already installed"
fi

# Catkin workspace
catkin_ws="$HOME/catkin_ws"

if [[ -d "$catkin_ws" ]]; then
    echo "Catkin workspace already exists, skipping."
else
    echo "Creating catkin workspace"
    mkdir -p "$catkin_ws/src"
    cd "$catkin_ws"
    catkin_make
    echo "Catkin workspace created and built."
fi

# Rviz_satellite
rviz_sat="$HOME/catkin_ws/src/rviz_satellite"

if [[ -d "$rviz_sat" ]]; then
    echo "rviz_satellite already exists, skipping."
else
    echo "Cloning rviz_satellite"
    cd "$HOME/catkin_ws/src"
    git clone https://github.com/nobleo/rviz_satellite.git
    cd "$HOME/catkin_ws"
    catkin_make
    echo "Rviz_satellite cloned and built."
fi

# innovusion_pointcloud
innovusion_pkgs=$(find "$SCRIPT_DIR" -name "ros-noetic-innovusion-driver-release*" -and -type f)
num_inno_pkg=$(echo "$innovusion_pkgs" | wc -l)

if [[ "$num_inno_pkg" -gt 1 ]]; then
    echo "Multiple Innovusion packages found, skipping"
else
    pkg_path=$(echo "$innovusion_pkgs" | wc -c)
    if [[ "$pkg_path" -lt 2 ]]; then
        echo "Innovusion package not found, skipping"
    else
        echo "Installing Innovusion package"
        sudo dpkg -i "$innovusion_pkgs"
        echo "Innovusion package installed"
    fi
fi

# object3d_detector
object3d_pkgs=$(find "$SCRIPT_DIR" -name "ros-noetic-object3d-detector*" -and -type f)
num_obj_pkg=$(echo "$object3d_pkgs" | wc -l)

if [[ "$num_obj_pkg" -gt 1 ]]; then
    echo "Multiple object3d_detector packages found, skipping"
else
    pkg_path=$(echo "$object3d_pkgs" | wc -c)
    if [[ "$pkg_path" -lt 2 ]]; then
        echo "object3d_detector package not found, skipping"
    else
        echo "Installing object3d_detector package"
        sudo dpkg -i "$object3d_pkgs"
        echo "object3d_detector package installed"
    fi
fi

# geolocation
geolocation_path="$HOME/catkin_ws/src/geolocation"

if [[ -d "$geolocation_path" ]]; then
    echo "geolocation already exists, skipping."
else
    echo "Cloning geolocation"
    cd "$HOME/catkin_ws/src"
    git clone https://github.com/SpawnageLoong/geolocation.git
    cd "$HOME/catkin_ws"
    catkin_make
    echo "geolocation cloned and built."
fi

cd "$HOME/catkin_ws"
rosdep install -a

sudo apt install gpsd

# bash aliases
touch $HOME/.bash_aliases
if grep -Fxq "alias wsSource='source ~/catkin_ws/devel/setup.bash'" $HOME/.bash_aliases; then
    echo "wsSource alias already exists, skipping."
else
    echo "alias wsSource='source ~/catkin_ws/devel/setup.bash'" >> $HOME/.bash_aliases
fi

if grep -Fxq "alias rosSource='source /opt/ros/noetic/setup.bash'" $HOME/.bash_aliases; then
    echo "rosSource alias already exists, skipping."
else
    echo "alias rosSource='source /opt/ros/noetic/setup.bash'" >> $HOME/.bash_aliases
fi

if grep -Fxq "alias start_lidar='~/catkin_ws/scripts/bringup.sh'" $HOME/.bash_aliases; then
    echo "start_lidar alias already exists, skipping."
else
    echo "alias start_lidar='~/catkin_ws/scripts/bringup.sh'" >> $HOME/.bash_aliases
fi

# bashrc
if grep -Fxq "source $HOME/.bash_aliases" $HOME/.bashrc; then
    echo "bashrc already sourced, skipping."
else
    echo "source $HOME/.bash_aliases" >> $HOME/.bashrc
fi

if grep -Fxq "rosSource" $HOME/.bashrc; then
    echo "rosSource already exists, skipping."
else
    echo "rosSource" >> $HOME/.bashrc
fi

if grep -Fxq "wsSource" $HOME/.bashrc; then
    echo "wsSource already exists, skipping."
else
    echo "wsSource" >> $HOME/.bashrc
fi

# bringup script
bringup_path="$HOME/catkin_ws/scripts/bringup.sh"
if [[ -f "$bringup_path" ]]; then
    echo "bringup.sh already exists, skipping."
else
    echo "Creating bringup.sh"
    touch "$bringup_path"
    echo "#!/bin/bash" >> $HOME/catkin_ws/scripts/bringup.sh
    echo "gpsd /dev/ttyUSB0" >> $HOME/catkin_ws/scripts/bringup.sh
    echo "roslaunch geolocation live.launch" >> $HOME/catkin_ws/scripts/bringup.sh
fi

echo "Installation complete"
