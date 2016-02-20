#!/bin/bash
#serverUrl=http://srtm.csi.cgiar.org/SRT-ZIP/SRTM_V41/SRTM_Data_GeoTiff/

serverUrl=http://mafreebox.freebox.fr/share/bR4v-TAcEYjBEqwj/

# télécharger et dézipper dans le répertoire out/
function dl_unzip() {
    curl -o out/$1.zip  ${serverUrl}$1.zip
    unzip -p out/$1.zip $1.tif > out/$1.tif
    rm out/$1.zip
}

file=srtm_36_04 # Metropole sud ouest
dl_unzip ${file}

file=srtm_38_04 # Metropole : corse et sud-est
dl_unzip ${file}

file=srtm_36_03 # Metropole : ouest
dl_unzip ${file}

file=srtm_37_03 # Metropole : centre
dl_unzip ${file}

file=srtm_38_03 # Metropole : est
dl_unzip ${file}

file=srtm_37_02 # Metropole : nord-ouest
dl_unzip ${file}

file=srtm_38_02 # Metropole : nord-est
dl_unzip ${file}




