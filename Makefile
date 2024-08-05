EXTENSIONS="app-schema,authkey,charts,css,csw,db2,dxf,excel,feature-pregeneralized,gdal,geopkg-output,grib,gwc-s3,importer,inspire,jp2k,libjpeg-turbo,mapml,mbstyle,mongodb,mysql,netcdf,netcdf-out,ogr,oracle,params-extractor,printing,querylayer,rat,sldService,sqlserver,vectortiles,wcs2_0-eo,web-resource,wmts-multi-dimensional,wps,wps-download,wps-jdbc,ysld"

COMMUNITY_MODULES="backup-restore,cog,colormap,datadir-catalog-loader,dds,dyndimension,features-autopopulate,features-templating,flatgeobuf,gdal,geopkg,gpxppio,graticule,gwc-azure-blob,gwc-sqlite,importer-jdbc,jdbcconfig,jdbcstore,jwt-headers,mbtiles,mbtiles-store,ncwms,netcdf-ghrsst,ogcapi,pgraster,security,spatialjson,stac-datastore,vsi,web-ogr,webp,wfs-freemarker,wps-longitudinal-profile"

.PHONY: install
install:
	./mvnw install -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -P$(EXTENSIONS),$(COMMUNITY_MODULES)

.PHONY: deploy
deploy:
	./mvnw deploy -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -DretryFailedDeploymentCount=10 \
        -DallowIncompleteProjects=true \
        -DaltDeploymentRepository='github::https://maven.pkg.github.com/camptocamp/geoserver-cloud-geoserver' \
        -Dmaven.resolver.transport=wagon \
        -P$(EXTENSIONS),$(COMMUNITY_MODULES)

