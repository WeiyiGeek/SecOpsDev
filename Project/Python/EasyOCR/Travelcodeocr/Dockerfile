FROM pytorch/pytorch
ARG service_home="/home/EasyOCR"

# Configure apt and install packages
RUN sed -i -e "s#archive.ubuntu.com#mirrors.aliyun.com#g" -e "s#security.ubuntu.com#mirrors.aliyun.com#g" /etc/apt/sources.list  && \
    apt-get update -y && \
    apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-dev \
    git \
    # cleanup
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists

# Clone EasyOCR repo OR COPY EasyOCR
#RUN mkdir "$service_home" \
#   && git clone "https://github.com/JaidedAI/EasyOCR.git" "$service_home" --depth=1
# 此处为了加快构建速度，已经将项目下载到了本地（放在Dockerfile 同级目录即可）
COPY ./EasyOCR "$service_home"

# Build（add pywsgi.WSGIServer module）
RUN cd "$service_home" \
    && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ \
    && python setup.py build_ext --inplace -j 4 \
    && python -m pip install -e . \
    && pip install flask \
    && pip install gevent \
    && pip3 install gevent-websocket
