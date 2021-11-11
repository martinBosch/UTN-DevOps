#! /bin/bash

### Aprovisionamiento de software ###

# Actualizo los paquetes de la maquina virtual
echo "--- apt-get update ---"
sudo apt-get update
echo "--- install pip 3 ---"
sudo apt-get install -y python3-pip
echo "--- install nginx ---"
sudo apt-get install -y nginx
echo "--- install python3 virtual environments ---"
sudo apt-get install -y python3-venv


cp /vagrant/app.py /home/vagrant/app.py
cp /vagrant/wsgi.py /home/vagrant/wsgi.py

# cd /vagrant

echo "--- create greeting-app-env ---"
python3 -m venv greeting-app-env
source greeting-app-env/bin/activate

echo "--- permisos para crear el socket ---"
sudo chown -R vagrant:vagrant /home/vagrant/*
sudo usermod -a -G vagrant www-data

echo "--- install Flask ---"
pip3 install Flask
echo "--- install gunicorn ---"
pip3 install gunicorn

deactivate


echo -e "[Unit]\nDescription=Gunicorn instance to serve greeting-app\nAfter=network.target\n[Service]\nUser=vagrant\nGroup=www-data\nWorkingDirectory=/home/vagrant/\nEnvironment="PATH=/home/vagrant/greeting-app-env/bin"\nExecStart=/home/vagrant/greeting-app-env/bin/gunicorn --workers 3 --bind unix:/home/vagrant/greeting-app.sock -m 007 wsgi:app\n[Install]\nWantedBy=multi-user.target\n"  >> /etc/systemd/system/greeting-app.service

sudo systemctl start greeting-app
sudo systemctl enable greeting-app

# python3 app.py
# flask run --host=0.0.0.0
# gunicorn --bind 0.0.0.0:5000 wsgi:app
# gunicorn --workers 2 --bind unix:greeting-app.sock -m 007 wsgi:app &

echo -e "server { listen 80; server_name localhost; location / { include proxy_params; proxy_pass http://unix:/home/vagrant/greeting-app.sock; } }" >> /etc/nginx/sites-available/greeting-app

sudo ln -s /etc/nginx/sites-available/greeting-app /etc/nginx/sites-enabled

sudo systemctl restart nginx

## aplicación

#echo "clono el repositorio"
#sudo git clone https://github.com/martinBosch/carpooleArg.git
#cd carpooleArg
#pip3 install -r requirements.txt
#python3 app.py
