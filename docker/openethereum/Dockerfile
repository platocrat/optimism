FROM openethereum/openethereum
USER root
RUN apk add --no-cache  openssl jq
COPY rollup-fullnode.json .
COPY rollup-fullnode.toml .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 9545
ENTRYPOINT ["sh", "/home/parity/entrypoint.sh"]
