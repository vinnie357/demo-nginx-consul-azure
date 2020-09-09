# demo-nginx-consul-azure
nginx k8s consul in aks

## Requirements

- azure storage bucket with controller tarball

    eg: controller-installer-3.7.0.tar.gz

- Controller
  - license file
  
    [trial license](https://www.nginx.com/free-trial-request-nginx-controller/)

- Nginx plus
  - cert
  - key
  
    [trial keys](https://www.nginx.com/free-trial-request/)

## Prep
  - create storage bucket with controller install tar.gz file
    - Example in ./storage
  - copy example admin vars to new file
    ```bash
      cp admin.auto.tfvars.example admin.auto.tfvars
    ```
  - update admin vars to your variables!

## Run
- login and run
  ```bash
  az login
  . demo.sh
  ```