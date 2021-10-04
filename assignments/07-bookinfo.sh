#!/bin/bash
CURRENT_DIR=$(pwd)
set -e

# Clone Ratings Service
echo
echo "<==== Clone Ratings Service Start ====>"
git clone https://github.com/exzenous/itkmitl-bookinfo-ratings.git ratings
cd ratings
git checkout dev
cd $CURRENT_DIR
echo "<==== Clone Ratings Service Ended ====>"
echo

# Clone Reviews Service
echo
echo "<==== Clone Reviews Service Start ====>"
git clone https://github.com/exzenous/itkmitl-bookinfo-reviews.git reviews
cd reviews
git checkout dev
cd $CURRENT_DIR
echo "<==== Clone Reviews Service Ended ====>"
echo

# Clone Details Service
echo
echo "<==== Clone Details Service Start ====>"
git clone https://github.com/exzenous/itkmitl-bookinfo-details.git details
cd details
git checkout dev
cd $CURRENT_DIR
echo "<==== Clone Details Service Ended ====>"
echo

# Clone Product Page Service
echo
echo "<==== Clone Product Page Service Start ====>"
git clone https://github.com/exzenous/itkmitl-bookinfo-productpage.git productpage
cd productpage
git checkout dev
cd $CURRENT_DIR
echo "<==== Clone Product Page Service Ended ====>"
echo

# Docker Build
docker build -t ratings ratings/
docker build -t reviews reviews/
docker build -t details details/
docker build -t productpage productpage/

# Docker Run - MongoDB
docker run -d --name mongodb-serv -p 27017:27017 \
  -v $CURRENT_DIR/ratings/databases:/docker-entrypoint-initdb.d \
  -e 'MONGODB_ROOT_PASSWORD=pass1234' \
  -e 'MONGODB_USERNAME=ratings' -e 'MONGODB_PASSWORD=pass1234' \
  -e 'MONGODB_DATABASE=ratings' bitnami/mongodb:5.0.2-debian-10-r2

# Docker Run - Ratings
docker run -d --name ratings -p 8080:8080 \
  --link mongodb-serv:mongodb -e 'MONGO_DB_URL=mongodb://mongodb:27017/ratings' \
  -e 'SERVICE_VERSION=v2' \
  -e 'MONGO_DB_USERNAME=ratings' -e 'MONGO_DB_PASSWORD=pass1234' ratings

# Docker Run - Details
docker run -d --name details -p 8081:9080 details

# Docker Run - Reviews
docker run -d --name reviews -p 8082:9080 \
 -e 'ENABLE_RATINGS=true' \
 --link ratings:ratings-serv -e 'RATINGS_SERVICE=http://ratings-serv:8080/ratings' reviews

# Docker Run - Product Page
docker run -d --name productpage -p 8083:9080 \
  --link reviews:reviews-serv -e 'REVIEWS_HOSTNAME=http://reviews-serv:9080'\
  --link details:details-serv -e 'DETAILS_HOSTNAME=http://details-serv:9080'\
  --link ratings:ratings-serv -e 'RATINGS_HOSTNAME=http://ratings-serv:8080' productpage

# Finishing
echo
echo "<=== Finished Build and Run ====>"
echo "< Ready to Preview at Port 8083 >"
echo