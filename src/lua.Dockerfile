# Set the base image
FROM debian

# Author
MAINTAINER David Barone

# Extra Metadata
LABEL version="1.0"
LABEL description="Lua application and web server."

# Update source list
RUN apt-get clean
RUN apt-get update
RUN apt-get -qy upgrade --show-upgraded

# install basic apps
RUN apt-get install -qy nano
RUN apt-get install -qy wget
RUN apt-get install -qy curl
RUN apt-get install -qy lua5.2
RUN apt-get install -qy luarocks
RUN apt-get install -qy liblua5.2-dev

#sqlite3 stuff
RUN apt-get install -qy sqlite3
RUN apt-get install -qy libsqlite3-dev

# postgres stuff
RUN apt-get install -qy git
RUN apt-get install -qy libpq-dev

#lighttpd stuff
RUN apt-get install -qy lighttpd

# Rocks
RUN luarocks install lsqlite3
RUN luarocks install luafilesystem
RUN luarocks install luasocket
RUN luarocks install md5
RUN luarocks install luasql-postgres PGSQL_INCDIR=/usr/include/postgresql

# Copy app files from host into image
COPY app /var/www/cgi-bin/

# Copy config
COPY ./etc/lighttpd.conf /etc/lighttpd/lighttpd.conf

# permissions (make sure database can be accessed by www-data user)
RUN chown www-data /var/www/cgi-bin
# RUN chown www-data /var/www/cgi-bin/cms.sl3
RUN chmod +x /var/www/cgi-bin/cgi.lua

# Clean-up
RUN apt-get -qy autoremove

# Expose ports
EXPOSE 80 443 81

# Setup entrypoint + command
CMD service lighttpd restart && tail -f /dev/null

