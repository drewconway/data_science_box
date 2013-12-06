Data Science Box
================

I often have to spin-up EC2 instances to do various data science(y) things with said instance.  These scripts are the result of having done that many times and needing many of the same tools to be available on those boxes.

Running these scripts will turn an Ubuntu 12.04.* LTS 64-bit server (tested) running on EC2 into a fully functioning data science box. Along with several base development libraries, the scripts installs and configures:

 - [R](http://www.r-project.org/) + [RStudio Server](http://www.rstudio.com/ide/docs/server/getting_started)
 - [shiny-server](http://www.rstudio.com/shiny/) (interactive web apps written in R)
 - Python + a suite of Python scientific computing libraries
 - [IPython](http://ipython.org/) + [IPython notebook](notebook) server ([stable](http://ipython.org/install.html))

Installation
============

Stick these two scripts in the same directory on your freshly deployed instance and type:

	$ ./data_science_box.sh

Then follow the on-screen instructions to configure the software.

Configuration
=============

The script takes care of all the on-box configuration, but if you wish to access RStudio Server, shiny-server, and IPython notebook server via a browser you will need to make sure the [Security Groups](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html) for the server you deploy allows in-bound traffic to the follow ports (defaults):

 - RStudio: 8787
 - shiny-server: 3838
 - IPython notebook: 8888
