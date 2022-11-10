#start with our base image (the foundation) - version 7.3
FROM php:7.2-apache

#install all the system dependencies and enable PHP modules 
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
      procps \
      nano \
      git \
      unzip \
      libicu-dev \
      zlib1g-dev \
      libxml2 \
      libxml2-dev \
      libreadline-dev \
      supervisor \
      cron \
      libzip-dev \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install \
      pdo_mysql \
      intl \
      zip && \
      rm -fr /tmp/* && \
      rm -rf /var/list/apt/* && \
      rm -r /var/lib/apt/lists/* && \
      apt-get clean

#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    && composer global require hirak/prestissimo --no-plugins --no-scripts

#set our application folder as an environment variable
ENV APP_HOME /var/www/html

# Install dependencies
COPY composer.json composer.json
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader \ 
    && rm -rf /root/.composer

#change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

#change the web_root to laravel /var/www/html/public folder
RUN sed -i -e "s/html/html\/public/g" /etc/apache2/sites-enabled/000-default.conf

# enable apache module rewrite
RUN a2enmod rewrite

#copy source files and run composer
COPY . $APP_HOME

# Finish composer
RUN composer dump-autoload --no-scripts --no-dev --optimize

# install all PHP dependencies
# RUN composer install --no-interaction

#change ownership of our applications
RUN chown -R www-data:www-data $APP_HOME

# get .env.sample from laravel repo and rename to .env
RUN curl -fsSL https://raw.githubusercontent.com/laravel/laravel/master/.env.example -o .env && \
    chgrp -R www-data storage bootstrap/cache && \
    chown -R www-data storage bootstrap/cache && \
    chmod -R ug+rwx storage bootstrap/cache && \
    touch storage/logs/laravel.log && chmod 775 storage/logs/laravel.log && \
    chown www-data storage/logs/laravel.log && \
    php artisan key:generate 