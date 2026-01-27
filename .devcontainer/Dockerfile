FROM ruby:3.4.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libvips-dev \
    git \
    curl \
    wget \
    fonts-freefont-ttf \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Yarn
RUN npm install -g yarn

# Download and install pdfium library
RUN ARCH=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/') && \
    wget -O /tmp/pdfium-linux.tgz "https://github.com/docusealco/pdfium-binaries/releases/latest/download/pdfium-linux-${ARCH}.tgz" && \
    mkdir -p /opt/pdfium && \
    tar -xzf /tmp/pdfium-linux.tgz -C /opt/pdfium && \
    cp /opt/pdfium/lib/libpdfium.so /usr/lib/ && \
    ldconfig && \
    rm -rf /tmp/pdfium-linux.tgz

# Set working directory
WORKDIR /workspace

# Install bundler
RUN gem install bundler

# Default command
CMD ["bash"]
