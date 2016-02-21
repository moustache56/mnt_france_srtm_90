# Modèle Numérique de Terrain (SRTM 90) avec Postgis

Installation de vagrant préalable, VM 64 bits. https://www.vagrantup.com/

```bash
git clone https://github.com/eric-pommereau/mnt_france_srtm_90
cd mnt_france_srtm_90
vagrant up
```

Connexion possible depuis l'hôte : 
```bash
psql -U srtm -p 5434
```

Détails de l'installation : [bootstrap.sh](./vagrant-provision/bootstrap.sh)




