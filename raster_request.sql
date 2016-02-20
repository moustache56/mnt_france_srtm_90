raster2pgsql -s 4326 -d -Y -I -t 30x30 out/*.tif srtm_metro |psql -d rastest
