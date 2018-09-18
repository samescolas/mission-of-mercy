yum update && yum -y install git            \
                          ruby              \
                          rubygems          \
                          ruby-devel        \
                          gcc               \
                          postgresql-server \
                          postgresql-devel  \

sudo gem install bundler

# install rvm and ruby version 2.0.0
curl -sSL https://get.rvm.io | bash
source ~/.rvm/scripts/rvm && rvm install 2.0.0 && rvm use 2.0.0

# install nodejs
curl --silent --location https://rpm.nodesource.com/setup_8.x | \
sudo bash - &&                                                  \
sudo yum -y install nodejs                                      \

sudo postgresql-setup initdb

bundle install && bundle update

useradd mom

rails s

