# gitea-s3backup-docker

> [!IMPORTANT]
> This repository has been archived and will no longer be maintained. I will keep it online for reference only.

This repository contains the [Dockerfile](./Dockerfile) to build a container based on __Gitea__ official image that includes the `s3cmd` tool to copy a backup file to an __S3__ compatible object storage.

## Origin

I initiated that project because I run __Gitea__ in a managed __Kubernetes__ environment and I could not find any documentation about how to handle backup in that setup.

I decided to build my own __Gitea__ image including `s3cmd` tool to copy a file to an object storage (namely Scaleway Object Storage). It also contains some scripts to backup Gitea. The full story is available on my blog.

## Workflow

The `Dockerfile` is used to build a new container image.

The build is automated through __Github Actions__ workflow defined in directory `.github/workflows/`.

__Dependabot__ is also configured on the __Github__ repository to update to the latest __Gitea__ image when it's available.

## Build the image

### Local build

Clone the repository and run `docker build` (or equivalent) from the root of the repository.

```bash
docker build -t <your image name>:<your tag> .
```

### Automated build through Github Actions

__Github Actions__ workflow configures automatic build of the container whenever some events happen in the repository. The workflow is described in file `.github/workflows/build-and-push.yaml`.


### Dependabot configuration

In addition to the __Github Actions__ workflow, I also added a __Dependabot__ configuration that creates a pull request whenever the `gitea/gitea` image used as base to build my own image is updated.

To configure __Dependabot__, browse to your __Github__ repository and go to __Insights__ -> __Dependency graph__ -> __Dependabot__.

Select __Enable Dependabot__.

Select __Create config__ file. It creates a file `.github/dependabot.yml`. Add this content to the file.

```yaml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/" # Location of package manifests
    schedule:
      interval: "daily"
```

__Dependabot__ will scan the `Dockerfile` on a daily basis and propose pull requests if it finds updates for the __Docker__ images used as base for build.

After some minutes, __Dependabot__ has created a pull request with the following content

```bash
# Using Github CLI to list active pull requests 
gh pr list
Showing 1 of 1 open pull request in pondichys/gitea-s3backup-docker

#1  Bump gitea/gitea from 1.14.2 to 1.14.5  dependabot/docker/gitea/gitea-1.14.5
```

You can accept and merge it to update your image with the last version of the official __Gitea__ image.

More info available on [Github Dependabot documentation page](https://help.github.com/github/administering-a-repository/configuration-options-for-dependency-updates).


## Test the container

1. Run the container locally

```bash
docker container run -d --env BUCKET_NAME=<your bucket for backup> --name gitea -p 3000:3000 -p 2222:22 my-gitea-test:0.3
```

2. Configure __Gitea__ using the include sqlite database and create an administrator.

3. Create a sample repository.

4. Get a shell from the running container.

```bash
docker container exec -it gitea bash
```

5. Create a `.s3cfg` file in /etc/s3cmd with the following content

```plaintext
[default]
host_base = s3.fr-par.scw.cloud
host_bucket = %(bucket)s.s3.fr-par.scw.cloud
bucket_location = fr-par
use_https = True

# Login credentials
access_key = <ACCESS_KEY TO INSERT HERE>
secret_key = <SECRET_KEY TO INSERT HERE>
```

6. Create a __Gitea__ dump - this must be run as the user running gitea executable (`git` in this case) and store it to a bucket of __Scaleway Object Storage__.

```bash
su - git
gitea dump -c /data/gitea/conf/app.ini

s3cmd -c /etc/s3cmd/.s3cfg put gitea-dump-1627901213.zip s3://seblab-k8s-backup

s3cmd ls s3://seblab-k8s-backup
2021-08-02 10:51        63578  s3://seblab-k8s-backup/gitea-dump-1627901213.zip
```

The backup works ok and the storage to object storage also.

7. Test the backup script `/scripts/gitea-backup.sh` that combines `gitea dump` and `s3cmd`.

```bash
/scripts/gitea-backup.sh
```

## How to use the image in Kubernetes

1. Create a __Kubernetes__ secret with the content of the `.s3cfg` file.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3cfg
type: Opaque
stringData:
  .s3cfg: |
    [default]
    host_base = <s3 entry point of your object storage>
    host_bucket = %(bucket)s.<insert same value as host_base here>
    bucket_location = <location of your S3 object storage bucket>
    use_https = True

    # Login credentials
    access_key = <your access key>
    secret_key = <your secret key>
```

2. Adapt some values and update the __Gitea__ Helm chart deployment.

- Specify your customized __Gitea__ image.

- Add an extra volume and mount the `.s3cfg` secret file in `/etc/s3cmd`

- Add environment variable `BUCKET_NAME` that contains the name of the __S3__ compatible object storage bucket where to store the __Gitea__ dump file.

3. Create a ServiceAccount, a Role and a RoleBinding in gitea namespace so that the backup job has the permissions to run.

4. Create a __Kubernetes Cronjob__ that runs the backup script.

YAML manifests for steps 3. and 4. are available in folder `k8s-resources/`.

