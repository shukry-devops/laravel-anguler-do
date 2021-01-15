### STAGE 1: BUILD ####
FROM node:10.16.3-alpine AS build
WORKDIR /usr/src/app
COPY ./frontend/package.json ./
#COPY ./frontend/package-lock.json ./
# To handle 'not get uid/gid'
RUN npm config set unsafe-perm true
RUN npm install -g @angular/cli
RUN npm install
COPY ./frontend .
RUN npm run build-prod
RUN ls -la /usr/src/app/dist 

FROM php:7.2-apache

# Install system dependencies
RUN apt-get update && \
           apt-get install -y vim zip unzip curl openssl
# Install system dependencies library
RUN apt-get install -y libonig-dev libxml2-dev libpng-dev

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install gd
RUN docker-php-ext-install pdo_mysql
#RUN docker-php-ext-install mbstring
RUN docker-php-ext-install bcmath

RUN a2enmod rewrite

# Install Composer

RUN curl -sS https://getcomposer.org/installer | php \
  && chmod +x composer.phar && mv composer.phar /usr/local/bin/composer

COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

#COPY ./BACKEND/composer.json .
#COPY ./BACKEND/composer.lock .
COPY ./backend .
###COPY DIST FILE###
COPY --from=build /usr/src/app/dist/ ./public/
RUN composer install
RUN chown -R www-data:www-data /var/www/html/

CMD apache2-foreground -k restart
