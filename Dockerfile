FROM python:3.11.0b3-alpine3.16

ARG USER=app
ARG UID=1001
ARG GID=1001

RUN adduser ${USER} -u $UID -g $GID -D \
    && mkdir -p /app \
    && chown -R ${USER}:${USER} /app
USER ${USER}

COPY --chown=$USER:$USER /index.html /app

WORKDIR /app

CMD python -m http.server 8000

EXPOSE 8000
