#!/bin/bash

# inspired by https://github.com/jackdb/pg-app-dev-vm/blob/master/Vagrant-setup/bootstrap.sh

apt-get -y install postgresql-9.4-postgis-2.1
apt-get -y install vim
apt-get -y install curl
apt-get -y install zip
updatedb

# Donwloading and unzip raster tile (west of France)
SRTM_USER=srtm
SRTM_PASS=srtm
SRTM_DB=srtm
PG_HBA=/etc/postgresql/9.4/main/pg_hba.conf
PG_CONF=/etc/postgresql/9.4/main/postgresql.conf
RASTER_DIR=/vagrant/rasters/

# Local solution to avoid downloading on the NET  (70 Mo each tile)
# RASTER_SERVER=http://mafreebox.freebox.fr/share/bR4v-TAcEYjBEqwj/
RASTER_SERVER=http://srtm.csi.cgiar.org/SRT-ZIP/SRTM_V41/SRTM_Data_GeoTiff/

# allow external connexions
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
cp /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.conf.old
sed -i 's/^local\s\+all\s\+all\s\+peer/local all all trust/g' $PG_HBA #local
echo "host    all             all             all                     md5" >> "$PG_HBA"

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

rasterList=("srtm_36_03" "srtm_38_04")

for rasterName in "${rasterList[@]}"
do
	echo Download and unzip ${RASTER_SERVER}${rasterName}.zip 
	curl -silent -o ${RASTER_DIR}${rasterName}.zip  ${RASTER_SERVER}${rasterName}.zip
	unzip -p ${RASTER_DIR}${rasterName}.zip ${rasterName}.tif > ${RASTER_DIR}${rasterName}.tif
done

# -d suppression de la table, -I créer un index, -Y mode copy, -t tile size
raster2pgsql -s 4326 -d -Y -I -t 30x30 ${RASTER_DIR}*.tif srtm_metro |psql -U srtm -d srtm

# testing a point (France Bretagne)
psql -U srtm -c "WITH point AS ( 
	SELECT 'Corse (Capu Ucellu)' as lieu, st_geomfromtext('POINT (8.87895 42.34474)', 4326) AS geom UNION
	SELECT 'Bretagne (Menez Hom)' as lieu, st_geomfromtext('POINT (-4.23425 48.22016)', 4326) AS geom
)
SELECT point.lieu, st_value(rast, geom) as altitude, st_summarystats(srtm.rast) as statistiques
FROM point JOIN srtm_metro srtm ON st_intersects(srtm.rast, point.geom);"

#testing statistics for smallest french administrative layer (commune) of a french departement

psql -U srtm -c "WITH zone AS (
SELECT
id_unite_niv3,
st_transform(geom, 4326)::geometry(MultiPolygon, 4326) AS geom
FROM zone3
WHERE id = 1
), cropped AS (
SELECT
st_clip(st_union(r.rast), min(z.geom)) AS rast,
min(geom) AS geom
FROM zone z
JOIN srtm_france r ON st_intersects(z.geom, r.rast)
)
SELECT s.*, st_AStext(geom)
FROM cropped c
, st_summarystats(c.rast) s"

