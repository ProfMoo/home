docker build -t profmoo/home .
# Ex: ./run.sh apply -auto-aprove
# Ex: ./run.sh plan
docker run profmoo/home $1 $2
