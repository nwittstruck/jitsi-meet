server {
    listen 8081 ssl;

    server_name jitsi.example.com;
    # set the root
    root <your path here>/jitsi-meet/;
    index index.html;

    # ssl
    ssl_certificate     /usr/local/etc/nginx/ssl/certs/myssl.crt;
    ssl_certificate_key /usr/local/etc/nginx/ssl/private/myssl.key;

    location ~ ^/([a-zA-Z0-9]+)$ {
        rewrite ^/(.*)$ / break;
        }
    # BOSH
    location /http-bind {
        proxy_pass      http://localhost:5280/http-bind;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $http_host;
    }

    # xmpp websockets
    location /xmpp-websocket {
        proxy_pass http://localhost:5280;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        tcp_nodelay on;
    }

    # recordings
     location /recordings {
        # we need to support cross origin requests:
         if ($http_origin) {
             add_header Access-Control-Allow-Origin *;
             add_header Access-Control-Allow-Methods "GET,POST,OPTIONS";
             add_header Access-Control-Allow-Headers   Content-Type;
             add_header Access-Control-Max-Age         86400;
         }
        autoindex on;
     }
}