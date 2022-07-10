FROM amazonlinux:2

# Create deploy directory
WORKDIR /deploy

# Install system dependencies
RUN yum -y install make gcc*
RUN curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
RUN yum -y install nodejs zip unzip

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install

# Install serverless
RUN npm install -g serverless

# Copy source
COPY . .

# Install app dependencies
RUN cd /deploy/functions && npm i --production && cd /deploy

#  Run deploy script
CMD ./deploy.sh ; sleep 2m
