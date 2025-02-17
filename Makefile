VERSION=`./mvnw help:evaluate -f geoserver/src/pom.xml -Dexpression=project.version -q -DforceStdout`

.PHONY: install
install: install-core install-extensions install-community

.PHONY: install-core
install-core:
	./mvnw install -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true

.PHONY: install-extensions
install-extensions:
	./mvnw install -f geoserver/src/extension/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -Prelease

.PHONY: install-community
install-community:
	./mvnw install -f geoserver/src/community/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -PcommunityReleaseCloud

.PHONY: deploy
deploy:
	./mvnw deploy -f geoserver/src/pom.xml --batch-mode -DskipTests -ntp -fae \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -DretryFailedDeploymentCount=10 \
        -DallowIncompleteProjects=true \
        -DaltDeploymentRepository='github::https://maven.pkg.github.com/camptocamp/geoserver-cloud-geoserver' \
        -Dmaven.resolver.transport=wagon \
        -Prelease,communityReleaseCloud


.PHONY: purge-dependencies
purge-dependencies: purge-dependencies-core purge-dependencies-extensions purge-dependencies-community

.PHONY: purge-dependencies-core
purge-dependencies-core:
	./mvnw dependency:purge-local-repository -f geoserver/src/pom.xml \
	-DactTransitively=true -DreResolve=false -Dverbose \
        -Dsort.skip=true -Dspotless.apply.skip=true

.PHONY: purge-dependencies-extensions
purge-dependencies-extensions:
	./mvnw dependency:purge-local-repository -f geoserver/src/extension/pom.xml \
	-DactTransitively=true -DreResolve=false -Dverbose \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -P$(EXTENSIONS)

.PHONY: purge-dependencies-community
purge-dependencies-community:
	./mvnw dependency:purge-local-repository -f geoserver/src/community/pom.xml \
	-DactTransitively=true -DreResolve=false -Dverbose \
        -Dsort.skip=true -Dspotless.apply.skip=true \
        -P$(COMMUNITY_MODULES)

.PHONY: uninstall
uninstall:
	echo version=$(VERSION) && \
	find $$HOME/.m2/repository/org/geoserver -type d -name $(VERSION) | xargs rm -rf {}


