FROM ubuntu:14.04

ENV PATH="/mattermost/bin:${PATH}" \
  MATTERMOST_UPDATED=20181206

RUN apt-get update && apt-get -y install curl netcat
RUN DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update && apt-get -qqy dist-upgrade \
  && apt-get -qqy --no-install-recommends install \
     $BUILD_PACKAGES \
  && echo 'en_US.ISO-8859-15 ISO-8859-15'>>/etc/locale.gen \
  && echo 'en_US ISO-8859-1'>>/etc/locale.gen \
  && echo 'en_US.UTF-8 UTF-8'>>/etc/locale.gen \
  && locale-gen \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL'>> /etc/sudoers \
  && echo "Installing Chef This may take a few minutes..." \
  && curl -L https://www.getchef.com/chef/install.sh | sudo bash \
  && echo "gem: --no-ri --no-rdoc" > ~/.gemrc \
  && /opt/chef/embedded/bin/gem install berkshelf \
  && apt-get -yqq autoremove \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/*

RUN mkdir -p /mattermost/data

ENV MM_VERSION=3.9.0

RUN curl https://releases.mattermost.com/$MM_VERSION/mattermost-team-$MM_VERSION-linux-amd64.tar.gz | tar -xvz

RUN rm /mattermost/config/config.json
COPY config.template.json /

COPY docker-entry.sh /
RUN chmod +x /docker-entry.sh
ENTRYPOINT ["/docker-entry.sh"]

EXPOSE 80

VOLUME /mattermost/data

WORKDIR /mattermost/bin
CMD ["platform"]
