# GeoServer Cloud GeoServer

This is the deployment repository for the customized GeoServer version used by GeoSever Cloud

## Install and deploy

On a local machine, before pushing to this github repository, in order to test the artifacts, run


```
make install
```

The CI build runs instead

```
make deploy
```

> `install` does not need to be run before `deploy`
