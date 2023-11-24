# How to use this script:
# Ex: ./docker_run.sh apply -auto-aprove
# Ex: ./docker_run.sh plan

docker build -t profmoo/home .
docker run profmoo/home $1 $2 $3
