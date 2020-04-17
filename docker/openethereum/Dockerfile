FROM openethereum/openethereum
USER root
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 9545
ENTRYPOINT ["sh", "/home/parity/entrypoint.sh"]
