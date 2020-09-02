# setup

- replace the dummy tar file with your own


## run

- run command
  ```bash
   . run.sh
  ```

## upload

Due to a provider bug, for upload type you will need upload the file to the created storage container.
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4377
 type = "Block blob"
 
once it is uploaded retrive the access url for the next stage: 
to do this you have to:
- navigate to your new uploaded file
- click generate SAS token and URL eg:
  https://controllersa4607.blob.core.windows.net/controller-demo4607/controller-installer-3.7.0.tar.gz?sp=r&st=2020-09-02T18:26:35Z&se=2020-09-03T02:26:35Z&spr=https&sv=2019-12-12&sr=b&sig=fjkdhsafkjhsdfjkjhfdsajf

- use this url for the controllerInstallUrl variable in admin.auto.tfvars
controllerInstallUrl = "https://controllersa4607.blob.core.windows.net/controller-demo4607/controller-installer-3.7.0.tar.gz?sp=r&st=2020-09-02T18:26:35Z&se=2020-09-03T02:26:35Z&spr=https&sv=2019-12-12&sr=b&sig=fjkdhsafkjhsdfjkjhfdsajf"

## cleanup

```bash
 . cleanup.sh
```