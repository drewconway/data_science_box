import sys
from IPython.lib import passwd

# Create hash of password
passwd_hash = passwd(sys.argv[1])
c  = open("passwd_hash.txt", "w")
c.write(passwd_hash)
c.close()