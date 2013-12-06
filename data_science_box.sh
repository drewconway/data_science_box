#!/bin/bash

# Bash script for setting up a fresh data scince server using an
# Ubuntu 12.04.* LTS 64-bit server running on an EC2

echo ""
echo "#########"
echo "This utility will setup a new Ubuntu 12.04 LTS Server instance on EC2 to run as a data science server."
echo "This script will install and configure the following tools:"
echo " - IPython (with notebook server)"
echo " - rstudio-server"
echo " - shiny-server"
echo "#########"

echo ""
echo "#########"
echo "To limit security risk, please create a new IPython profile with a password."
echo "#########"

read -p "Profile name for IPython server: " profileName
read -s -p "Password for $profileName: " passwd
echo ""
read -s -p "Confirm password: " passwd_confirm
if [ "$passwd" != "$passwd_confirm" ] 
	then
		echo ""
		echo "IPython profile passwords did not match! Please re-run script, and be careful!"
		exit
fi

echo ""
echo "#########"
echo "Now create a self-signed SSL key to encrypt password transmission in the browser."
echo "#########"

path_to_pem="/home/ubuntu/.ssh/ipython_$profileName.pem"
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout $path_to_pem -out $path_to_pem

echo ""
echo ""
echo "#########"
echo "To limit security risk, create a user and password for rstudio-server"
echo "#########"

read -p "RStudio user group [rstudio_users]: " rstudioGroup
rstudioGroup=${rstudioGroup:-rstudio_users}
read -p "Create RStudio user: " rstudioUser
read -s -p "Password for $rstudioUser: " rstudioPassword
read -s -p "Confirm password: " rstudioPassword_confirm
if [ "$rstudioPassword" != "$rstudioPassword_confirm" ]
	then
		echo ""
		echo "rstudio-server user passwords did not match! Please re-run script, and be careful!"
		exit
fi

echo ""
echo ""

sudo groupadd $rstudioGroup
sudo useradd -m -N $rstudioUser
echo "$rstudioUser:$rstudioPassword" | sudo chpasswd
sudo usermod -G $rstudioGroup $rstudioUser
sudo chmod -R +u+r+w /home/%rstudioUser

echo ""
echo "New user group $rstudioGroup created. Add users to this group for access to rstudio-server."
echo ""

echo ""
echo "#########"
echo "Adding the CRAN mirrors to apt-get"
echo "#########"

# Need to add the R repo to our sources.list, add the GPG key
echo "deb http://lib.stat.cmu.edu/R/CRAN/bin/linux/ubuntu precise/" | sudo tee -a /etc/apt/sources.list
gpg --keyserver pgp.mit.edu --recv-key 51716619E084DAB9
gpg -a --export 51716619E084DAB9 > cran.asc
sudo apt-key add cran.asc
sudo rm cran.asc

echo ""
echo "#########"
echo "Adding base developer dependencies and packages. This may take some time."
echo "#########"

# Get the all the support libraries. There very well may be unnecessary things here
# but I am too lazy to check
sudo apt-get update -qq
sudo apt-get install -y -qq ubuntu-dev-tools gdebi-core libapparmor1 psmisc libtool autoconf automake uuid-dev git octave 

echo ""
echo "#########"
echo "Downloading, installing, and configuring R and rstudio-server"
echo "#########"

sudo apt-get install -y -qq r-base r-base-dev
mkdir Downloads
cd Downloads
wget http://download2.rstudio.org/rstudio-server-0.97.551-amd64.deb
sudo gdebi -q -n rstudio-server-0.97.551-amd64.deb
rserver_config="/etc/rstudio/rserver.conf"
rsession_config="/etc/rstudio/rsession.conf"
sudo touch $rserver_config
sudo touch $rsession_config
echo "auth-required-user-group=$rstudioGroup"  | sudo tee -a $rserver_config
echo "r-cran-repos=http://cran.wustl.edu/"  | sudo tee -a $rsession_config
sudo rstudio-server restart

echo ""
echo "#########"
echo "Downloading, installing, and configuring shiny-server"
echo "#########"

sudo su - \
    -c "R -e \"install.packages('shiny', repos='http://cran.rstudio.com/')\""
wget http://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-0.4.0.15-amd64.deb
sudo gdebi -n shiny-server-0.4.0.15-amd64.deb
sudo mkdir /srv/shiny-server/examples
sudo cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/examples/

echo ""
echo "#########"
echo "Downloading and installing Python development and scientific support libraries"
echo "#########"

sudo apt-get install -y -qq python-dev python-scipy python-numpy python-matplotlib python-pandas python-nose python-sympy python-scikits.learn

echo ""
echo "#########"
echo "Downloading and installing Python setuptools"
echo "#########"

# Download and install setuptools for Python
wget http://pypi.python.org/packages/source/s/setuptools/setuptools-0.6c11.tar.gz#md5=7df2a529a074f613b509fb44feefe74e
tar -xvf setuptools-0.6c11.tar.gz
cd setuptools-0.6c11/
sudo python setup.py install --quiet	

echo ""
echo "#########"
echo "Downloading and installing IPython support libraries"
echo "#########"

# Install supporting Python libs
cd ..
sudo easy_install Cython oct2py rpy2 wx azure

echo ""
echo "#########"
echo "Installing IPython!"
echo "#########"

# Install iPython!
sudo -y -qq easy_install ipython[all]

echo ""
echo "#########"
echo "Creating IPython profile"
echo "#########"

# Create a profile for the ipython server, and install MathJax awesome while you're at it!
cd ..
ipython passwd.py $passwd
passwd_file="passwd_hash.txt"
passwd_hash=`cat $passwd_file`
rm $passwd_file
ipython profile create $profileName
notebook_config="/home/ubuntu/.ipython/profile_$profileName/ipython_notebook_config.py"


# Append to the config file the things you want
echo "c.IPKernelApp.pylab = 'inline' " | sudo tee -a $notebook_config
echo "c.NotebookApp.ip = '*' " | sudo tee -a $notebook_config
echo "c.NotebookApp.open_browser = False " | sudo tee -a $notebook_config
echo "c.NotebookApp.password = u'$passwd_hash'" | sudo tee -a $notebook_config
echo "c.NotebookApp.port = 8888" | sudo tee -a $notebook_config
echo "c.NotebookApp.certfile = '$path_to_pem'" | sudo tee -a $notebook_config

# Clean up
sudo rm -rf Downloads


# Start up the server!!
echo ""
echo "#########"
echo "INSTALLTION COMPLETE!"
echo "The RStudio server is available at http:[server-url]:8787"
echo "shiny-server pages can be accessed at http:[server-url]:3838"
echo "To start the IPython notebook server type: sudo ipython notebook --profile=$profileName"

exit