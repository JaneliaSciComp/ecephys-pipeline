FROM oraclelinux:8 as prebuilder

# This is a oraclelinux-8 based container 
# prepared for a full matlab install

#### Get Dependencies ####

RUN dnf update -y && \
    dnf install -y dnf-utils

RUN dnf -y install --nogpgcheck \
        https://download.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
        https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm

RUN dnf group install -y "Development Tools" && \
    dnf install -y \
        ca-certificates \
        alsa-lib \
        atk \
        ffmpeg-libs \
        cairo \
        cairo-gobject \
        cups-libs \
        dbus-libs \
        fontconfig \
        gdk-pixbuf2 \
        gstreamer1-plugins-base \
        gstreamer1 \
        gtk3 \
        nspr \
        nss \
        pam \
        pango \
        python3-libs \
        libselinux \
        libSM \
        libsndfile \
        libX11 \
        libX11-xcb \
        libxcb \
        libXcomposite \
        libXcursor \
        libXdamage \
        libXext \
        libXfixes \
        libXft \
        libXi \
        libXinerama \
        libXrandr \
        libXrender \
        libXt \
        libXtst \
        libXxf86vm \
        procps-ng \
        sudo \
        zlib

RUN dnf install -y \
        which

# To avoid inadvertently polluting the / directory, use root's home directory 
# while running MATLAB.
WORKDIR /root

#### Install MATLAB in a multi-build style ####
FROM prebuilder as matlab-installer

######
# Create a self-contained MATLAB installer using these instructions:
#
# https://www.mathworks.com/help/install/ug/download-only.html
#
# You must be an administrator on your license to complete this workflow
# You can run the installer on any platform to create a self-contained MATLAB installer
# When creating the installer, on the "Folder and Platform Selection" screen, select "Linux (64-bit)"
#
# Put the installer in a directory called matlab-install
# Move that matlab-install folder to be in the same folder as this Dockerfile
######

# Add MATLAB installer to the image
ADD matlab-install /matlab-install/

# Copy the file matlab-install/installer_input.txt into the same folder as the 
# Dockerfile. The edit this file to specify what you want to install. NOTE that 
# at a minimum you will need to have changed the following set of parameters in 
# the file.
#   fileInstallationKey
#   agreeToLicense=yes
#   Uncomment products you want to install
ADD matlab_installer_input.txt /matlab_installer_input.txt

# Install MATLAB
RUN cd /matlab-install && \
    chmod +x ./install && \
    ./install -mode silent \
        -inputFile /matlab_installer_input.txt \
        -outputFile /tmp/mlinstall.log \
        -destinationFolder /usr/local/MATLAB \
    ; EXIT=$? && cat /tmp/mlinstall.log && test $EXIT -eq 0

#### Build final container image ####
FROM prebuilder

COPY --from=matlab-installer /usr/local/MATLAB/*.txt /usr/local/MATLAB/
COPY --from=matlab-installer /usr/local/MATLAB/*.xml /usr/local/MATLAB/
COPY --from=matlab-installer /usr/local/MATLAB/appdata /usr/local/MATLAB/appdata
COPY --from=matlab-installer /usr/local/MATLAB/resources /usr/local/MATLAB/resources
COPY --from=matlab-installer /usr/local/MATLAB/toolbox /usr/local/MATLAB/toolbox
COPY --from=matlab-installer /usr/local/MATLAB/sys /usr/local/MATLAB/sys
COPY --from=matlab-installer /usr/local/MATLAB/bin /usr/local/MATLAB/bin
COPY --from=matlab-installer /usr/local/MATLAB/runtime /usr/local/MATLAB/runtime
COPY --from=matlab-installer /usr/local/MATLAB/mcr /usr/local/MATLAB/mcr
COPY --from=matlab-installer /usr/local/MATLAB/ui /usr/local/MATLAB/ui
COPY --from=matlab-installer /usr/local/MATLAB/polyspace /usr/local/MATLAB/polyspace
COPY --from=matlab-installer /usr/local/MATLAB/derived /usr/local/MATLAB/derived
COPY --from=matlab-installer /usr/local/MATLAB/rtw /usr/local/MATLAB/rtw
COPY --from=matlab-installer /usr/local/MATLAB/simulink /usr/local/MATLAB/simulink
COPY --from=matlab-installer /usr/local/MATLAB/extern /usr/local/MATLAB/extern
COPY --from=matlab-installer /usr/local/MATLAB/cefclient /usr/local/MATLAB/cefclient
COPY --from=matlab-installer /usr/local/MATLAB/interprocess /usr/local/MATLAB/interprocess
COPY --from=matlab-installer /usr/local/MATLAB/remote /usr/local/MATLAB/remote
COPY --from=matlab-installer /usr/local/MATLAB/java /usr/local/MATLAB/java

RUN sed -i "/examples/d" /usr/local/MATLAB/toolbox/local/pathdef.m

# Add a soft link into /usr/local/bin
RUN ln -s /usr/local/MATLAB/bin/matlab /usr/local/bin/matlab

ARG LICENSE_SERVER
# Specify the host and port of the machine that serves the network licenses 
# if you want to bind in the license info as an environment variable. This 
# is the preferred option for licensing. It is either possible to build with 
# something like --build-arg LICENSE_SERVER=27000@MyServerName, alternatively
# you could specify the license server directly using
#       ENV MLM_LICENSE_FILE=27000@flexlm-server-name
ENV MLM_LICENSE_FILE=$LICENSE_SERVER

# setup mex in your container
RUN /usr/local/MATLAB/bin/mex -v -setup C++

CMD ["/usr/local/bin/matlab"]
