.PHONY: install
install:
	./mvnw install -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -PallExtensions,communityRelease \
        -Dsort.skip=true -Dspotless.apply.skip=true

.PHONY: deploy
deploy:
	./mvnw deploy -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -PallExtensions,communityRelease \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -DretryFailedDeploymentCount=10 \
        -DallowIncompleteProjects=true \
        -DaltDeploymentRepository='github::https://maven.pkg.github.com/camptocamp/geoserver-cloud-geoserver' \
        -Dmaven.resolver.transport=wagon

