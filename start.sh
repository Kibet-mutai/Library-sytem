#!/bin/bash
# get .env.sample from laravel repo and rename to .env
curl -fsSL https://raw.githubusercontent.com/laravel/laravel/master/.env.example -o .env

# Change access rights for the Laravel folders
# in order to make Laravel able to access 
# cache and logs folder.
chgrp -R www-data storage bootstrap/cache && \
    chown -R www-data storage bootstrap/cache && \
    chmod -R ug+rwx storage bootstrap/cache && \
# Create log file for Laravel and give it write access
# www-data is a standard apache user that must have an
# access to the folder structure
touch storage/logs/laravel.log && chmod 775 storage/logs/laravel.log && 
chown www-data storage/logs/laravel.log && 
php artisan key:generate
php artisan migrate:fresh --seed && echo "Done..."