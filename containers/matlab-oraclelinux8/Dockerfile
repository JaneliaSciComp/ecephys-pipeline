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

RUN dnf install -y \
	wget \
	unzip \
	ca-certificates

# To avoid inadvertently polluting the / directory, use root's home directory 
# while running MATLAB.
WORKDIR /root


ARG MATLAB_INSTALL_LOCATION=/usr/local/MATLAB
# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards.
# If mpm fails to install successfully, then print the logfile in the terminal, otherwise clean up.
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm \ 
    && chmod +x mpm \
    && ./mpm install \
    --release=r2022b \
    --destination=${MATLAB_INSTALL_LOCATION} \
    --products MATLAB Curve_Fitting_Toolbox Parallel_Computing_Toolbox Statistics_and_Machine_Learning_Toolbox Signal_Processing_Toolbox \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && rm -f mpm /tmp/mathworks_root.log \
    && ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab



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

