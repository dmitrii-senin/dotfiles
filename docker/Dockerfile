FROM ubuntu:latest

RUN apt update && \
apt install -y curl clang-15 && \
rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-15 50

RUN curl -SL https://raw.githubusercontent.com/dmitrii-senin/dotfiles/master/bootstrap.sh | sh

CMD ["/bin/zsh"]
