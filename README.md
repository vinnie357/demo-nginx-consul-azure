# demo-nginx-consul-azure
nginx k8s consul in aks

## Prep
  - create storage bucket with controller install tar.gz file
  - copy example admin vars to new file
    ```bash
      cp admin.auto.tfvars.example admin.auto.tfvars
    ```
  - update admin vars to your variables!

## Run

```bash
az login
. demo.sh
```