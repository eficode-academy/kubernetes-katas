openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls-key.key -out tls-cert.crt
openssl dhparam -out dhparam.pem 2048