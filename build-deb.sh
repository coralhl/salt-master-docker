#!/bin/bash

# Сборка
docker buildx build --output type=docker -f Dockerfile -t coralhl/salt-master:latest .

# Заливка в регистр
docker push coralhl/salt-master:latest
