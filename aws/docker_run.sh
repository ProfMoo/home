docker build -t profmoo/home .
# Ex: ./docker_run.sh apply -auto-aprove
# Ex: ./docker_run.sh plan
docker run profmoo/home $1 $2 $3
