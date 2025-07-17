FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -m mom && echo "mom ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN apt-get update && apt-get install -y curl

RUN curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh

RUN bash nodesource_setup.sh

RUN apt-get install -y \
  git gem curl build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev \
  bison autoconf libgdbm-dev libncurses5-dev libtool libpq-dev nodejs \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
  cd ~/.rbenv && src/configure && make -C src && \
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
  ~/.rbenv/plugins/ruby-build/install.sh

 
#USER mom

COPY . /root/app
#COPY . /home/mom/app

#WORKDIR /home/mom/app
WORKDIR /root/app

RUN /root/.rbenv/bin/rbenv install 2.3.8 && /root/.rbenv/bin/rbenv global 2.3.8
#RUN /root/.rbenv/bin/rbenv install 2.0.0-p648 && /root/.rbenv/bin/rbenv global 2.0.0-p648

RUN /root/.rbenv/shims/gem install bundler -v 1.17.3

RUN /root/.rbenv/shims/bundle install

RUN /root/.rbenv/shims/bundle update execjs


#RUN /root/.rbenv/shims/gem install rails && /root/.rbenv/bin/rbenv rehash

#CMD ["bash"]

#RUN source /root/app/.env.2024

CMD ["tail", "-f", "/dev/null"]

#CMD ["bash"]
#ENTRYPOINT ["./run.sh"]
