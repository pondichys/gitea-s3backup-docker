# gitea-s3backup-docker

This repository contains the [Dockerfile](./Dockerfile) to build a container based on __Gitea__ official image that includes the `s3cmd` tool to copy a backup file to an __S3__ compatible object storage.

## Origin

I initiated that project because I run __Gitea__ in a managed __Kubernetes__ environment and I could not find any documentation about how to handle backup in that setup.

I decided to build my own __Gitea__ image including `s3cmd` tool to copy a file to an object storage (namely Scaleway Object Storage). It also contains some scripts to backup Gitea. The full story is available on my blog.

## Workflow

The `Dockerfile` is used to build a new container image.

The build is automated through Github Actions workflow defined in directory `.github/workflows/`.

Dependabot is also configured on the Github repository to update to the latest Gitea image when it's available.

## Build the image

### Local build

Clone the repository and run docker build (or equivalent) from the root of the repository.

```bash
docker build -t <your image name>:<your tag> .
```

### Automated build through Github Actions

Github Actions workflow configures automatic build of the container whenever some events happen in the repository. The workflow is described in file .github/workflows/build-and-push.yaml.


### Dependabot configuration

In addition to the Github Actions workflow, I also added a Dependabot configuration that creates a pull request whenever the gitea/gitea image used as base to build my own image is updated.

## Test the container

1. Run the container locally

```bash
docker container run -d --name gitea -p 3000:3000 -p 2222:22 my-gitea-test:0.1
```

2. Configure Gitea using the include sqlite database and create an administrator.

3. Create a sample repository.

4. Get a shell from the running container.

```bash
docker container exec -it gitea bash
```

5. Create a `.s3cfg` file in the home directory of the `root` user with the following content

```plaintext
[default]
# Object Storage Region FR-PAR
host_base = s3.fr-par.scw.cloud
host_bucket = %(bucket)s.s3.fr-par.scw.cloud
bucket_location = fr-par
use_https = True

# Login credentials
access_key = <ACCESS_KEY TO INSERT HERE>
secret_key = <SECRET_KEY TO INSERT HERE>
```

6. Create a Gitea dump - this must be run as the user running gitea executable (`git` in this case) and store it to a bucket of Scaleway Object Storage.

```bash
su - git
gitea dump -c /data/gitea/conf/app.ini

s3cmd put gitea-dump-1627901213.zip s3://seblab-k8s-backup

s3cmd ls s3://seblab-k8s-backup
2021-08-02 10:51        63578  s3://seblab-k8s-backup/gitea-dump-1627901213.zip
```

The backup works ok and the storage to object storage also.

7. Test the backup script `/scripts/gitea-backup.sh` that combines `gitea dump` and `s3cmd`.

```bash
/scripts/gitea-backup.sh
```

## How to use the image in Kubernetes

Create a Kubernetes secret with the content of the `.s3cfg` file.

Adapt some values of the Gitea Helm chart deployment.

- Specify your customized Gitea image.

- Add an extra volume and mount the `.s3cfg` secret file.

- Add environment variable `BUCKET_NAME` that contains the name of the S3 compatible object storage bucket where to store the Gitea dump file.

Create a Kubernetes Cronjob that runs 

```bash
kubectl exec gitea -n gitea -- /scripts/gitea-backup.sh
```