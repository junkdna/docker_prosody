# Container for latest-greatest prosody.im
## Intro
Lorem Ipsum ...

## Docker secrets
You can use docker secrets for the following variables:

- RUN\_AS\_FILE
- RUN\_AS\_GROUP\_FILE
- HTTP\_UPLOAD\_SECRET\_FILE

# Compose snippet
Works in concert with `jwilder/docker-gen`, nginx-proxy, and `jrcs/letsencrypt-nginx-proxy-companion`

```yaml
  jabber:
    build:
      context: prosody
    image: repo-local/prosody:latest
    container_name: prosody
    depends_on:
      - database
      - nginx-proxy
    networks:
      - nginx-proxy
    ports:
      - "5222:5222"
      - "5269:5269"
    volumes:
      - /volumes/config/prosody:/etc/prosody
      - /volumes/certs:/certs:ro
      - /dev/log:/dev/log
      - /var/run/systemd/journal/socket:/var/run/systemd/journal/socket
      - /etc/passwd:/etc/passwd:ro
      - /etc/group:/etc/group:ro
    environment:
      - RUN_AS=prosody
      - JABBER_HOST=jabber.example.com
      - HTTP_UPLOAD_SECRET=it-is-very-very-secret
      - VIRTUAL_HOST=jabber.example.com
      - VIRTUAL_NETWORK=nginx-proxy
      - LETSENCRYPT_HOST=jabber.example.com
      - LETSENCRYPT_EMAIL=root@example.com
```
