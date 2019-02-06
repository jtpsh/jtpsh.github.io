FROM bionic:latest
RUN apt-get update && apt-get install -y apache2
RUN mkdir /var/www/jtp.sh
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY apache/jtp.sh.conf /etc/apache2/sites-enabled/jtp.sh.conf
COPY output/ /var/www/jtp.sh
EXPOSE 80
CMD apachectl -D FOREGROUND
