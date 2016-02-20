#!/bin/bash
sudo apt-get -y install postgresql-9.4-postgis-2.1
sudo apt-get -y install vim
sudo apt-get -y install curl

SRTM_USER=srtm
SRTM_PASS=srtm
SRTM_DB=srtm
PG_HBA=/etc/postgresql/9.4/main/pg_hba.conf
PG_CONF=/etc/postgresql/9.4/main/postgresql.conf
RASTER_DIR=/vagrant/out/

# allow external connexions
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# allow connexion trusted f:rom local
sed -i 's/^local\s\+all\s\+all\s\+peer/local all all trust/g' $PG_HBA

# restart for taking effect from previous command
service postgresql restart

# creating role and db
cat << EOF | su - postgres -c psql
CREATE ROLE $SRTM_USER WITH PASSWORD '$SRTM_PASS' SUPERUSER LOGIN;
CREATE DATABASE $SRTM_DB OWNER $SRTM_DB;
EOF

# creating extension
psql -U srtm -c "CREATE EXTENSION postgis;"

# check installation
psql -U srtm -c "SELECT postgis_full_version();"

# raster2pgsql -s 4326 -d -Y -I -t 30x30 out/*.tif srtm_metro |psql -U srtm -d srtm

# -d suppression de la table, -I créer un index, -Y mode copy, -t tile size
raster2pgsql -s 4326 -d -Y -I -t 30x30 $RASTER_DIR/srtm_36_03.tif srtm_metro |psql -U srtm -d srtm

# testing a point (France Bretagne)
psql -U srtm -c "WITH point AS ( SELECT 'Bretagne' as lieu, st_geomfromtext('POINT (-3.94316 48.24974)', 4326) AS geom)
SELECT point.lieu, st_value(rast, geom) as alt, st_summarystats(srtm.rast) as stats
FROM point
JOIN srtm_metro srtm ON st_intersects(srtm.rast, point.geom)
;"
