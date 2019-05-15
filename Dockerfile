FROM php:7.2.3-apache-stretch

# Install "git" and "lib*-dev" packages for GRAV installation.
# Also "sass" for compiling scss to css.
RUN apt-get update && apt-get install -y \
    git \
    libjpeg62-turbo-dev libpng-dev libfreetype6-dev \
    sass \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd zip

## Set "C.UTF-8" for UTF-8 Support.
ENV LC_ALL C.UTF-8

# Configure Apache
COPY grav.conf /etc/apache2/sites-available/grav.conf
RUN a2enmod rewrite && a2dissite 000-default && a2ensite grav

# Install GRAV
WORKDIR /var/www/grav
RUN git clone https://github.com/getgrav/grav.git /var/www/grav
RUN /var/www/grav/bin/grav install
RUN /var/www/grav/bin/gpm install admin -y
RUN /var/www/grav/bin/gpm index

# Change the owner of GRAV files because GRAV runs as "www-data" user.
RUN chown -R www-data:www-data /var/www/grav

# Create New User. 
ARG ADMIN_USER=admin
ARG ADMIN_PASSWORD=passsword-GRAV@2019
ARG ADMIN_EMAIL=sample@getgrav.org
ARG ADMIN_PERMISSIONS=b
ARG ADMIN_FULLNAME="Grav Admin"
ARG ADMIN_TITLE=Administrator
RUN /var/www/grav/bin/plugin login newuser \
  --user="${ADMIN_USER}" \
  --password="${ADMIN_PASSWORD}" \
  --email="${ADMIN_EMAIL}" \
  --permissions="${ADMIN_PERMISSIONS}" \
  --fullname="${ADMIN_FULLNAME}" \
  --title="${ADMIN_TITLE}"

# Change access control.
WORKDIR /var/www/grav
RUN chown -R www-data:staff /var/www/grav/
RUN find . -type f | xargs chmod 664
RUN find ./bin -type f | xargs chmod 775
RUN find . -type d | xargs chmod 775
RUN find . -type d | xargs chmod +s