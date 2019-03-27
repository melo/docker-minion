# Minion Docker Image

This Docker image allows you to run a [Minion](https://metacpan.org/pod/Minion) job queue.

The image provides:

* the Web UI;
* a worker setup, that allows you to load your own task classes.

The image supports both Postgres or MySQL-compatible databases.


## Quick demo

You'll need a working Docker setup and `docker-compose`.

Clone this repository:

    git clone https://github.com/melo/docker-minion.git

Start it up:

    cd docker-minion/demo
    docker-compose up -d

This will start a MySQL database, the Web UI and a worker. Open the Web UI at [http://127.0.0.1:3000/](). Click around to get to know it. Notice that all the items at the top are clickable, and will show you filtered lists of jobs, or the list of connected workers.

At the end the items in the listings there is a `>` symbol, that will show you the raw data for the item in question.

The Web UI includes a simple "job creation" API, so we can start a bunch of jobs using the Echo task code included in this demo:

    for i in `seq 1 200` ; do curl -d "{ \"count\": $i }" http://127.0.0.1:3000/job/echo ; echo ; done

This will create 200 jobs. Click around in the Web UI to see the jobs. Expand them with the `>` link at the end of the items in the listing.

Each worker defaults to 4 concurrent jobs (the badge near the _Active_ at the top never goes above 4). One way to increase the concurrency is by adding more workers:

    docker-compose up -d --scale worker=5

Look at the Web UI again. You'll see that the badge for workers will show 6. This is because docker-compose will kill the original worker and start 5 new ones, and Minion takes a bit to clear old workers.

Repeat the log generation script above, to generate 200 more workers. You'll see that there are now 20 active jobs at a time (4 jobs per worker, 5 workers).

After your are done, clean up with:

    docker-compose down


## Using this image

To use this image you'll need to start at least a Worker container, and provide it with credentials for a Postgres or MySQL database. Starting a container for the Web UI is optional but recommended.

See below on how to "Build your own image" to include your own worker tasks code.

You can start your worker with direct Docker commands, or you can tweak the [`docker-compose.yml`](https://github.com/melo/docker-minion/blob/master/demo/docker-compose.yml) from the demo.

After you have your image, you can start a worker with:

    docker run -d --name my_worker -e MINION_SOURCE=... \
           -e MINION_PLUGINS=... <your-image-name>      \
           worker --mode production

See below for the configuration options, in particular `MINION_SOURCE` and `MINION_PLUGINS` environment variables.



### Building your own image

Although you can use this image as-is for the Web UI interface, to make proper use of the workers you will need to load your own worker classes.

To do this, we recommend that you:

* define you worker classes dependencies using a `cpanfile` file;
* (optional but recommended) use [`Carton`](https://metacpan.org/pod/Carton) to freeze your dependencies versions and create a `cpanfile.snapshot` file;
* create a `Dockerfile` for you.

A simple `Dockerfile` (assuming you'll use Carton) would look like this:

```
FROM melopt/alpine-perl-devel AS builder

RUN apk --no-cache add <add any packages you might need here to build your deps>

COPY cpanfile cpanfile.snapshot /app/
RUN  cd /app && carton install --deployment && rm -rf local/cache ~/.cpanm*
COPY . /app/

FROM melopt/alpine-perl-runtime

WORKDIR /app

RUN apk --no-cache add <add any packages you might need here to run your workers>

COPY --from=builder /app /app
```

(**Please note well**: the base image assumes that your code will be under `/app` inside the image)


### Configuration

The image uses two environment variables for configuration:

* `MINION_SOURCE`: the database connect string. See [Minion::Backend::Pg](https://metacpan.org/pod/Minion::Backend::Pg) or  [Minion::Backend::mysql](https://metacpan.org/pod/Minion::Backend::mysql) to understand the format to use;
* `MINION_PLUGINS`: the Perl package prefix of your workers classes. The worker script will find and load all the modules under that package. The files should be copied to For example, if you use `My::Workers` and you have 


## Starting everything up

This image contains three scripts that do all the magic, under `/minion/bin`.

The [`entrypoint`](https://github.com/melo/docker-minion/blob/master/bin/entrypoint) script is the Docker entrypoint that implements the small sugar layer that makes using this image simpler.

You can see all the commands that this entrypoint script provides with:

    docker run --rm melopt/minion

or...

    docker run --rm melopt/minion help

### Web UI

To start the Web UI, use:

    docker run -d --name my_worker -e MINION_SOURCE=... \
           -p 3000:127.0.0.1:3000                       \
           <your-image-name> webui --mode production

Please note that there is no authentication on the Web UI. We therefore start it at http://127.0.0.1:3000/ and not on a possibly exposed network interface. We strongly recommend that you setup a reverse proxy (like [Traefik](https://traefik.io "Traefik - The Cloud Native Edge Router") or [nginx](https://www.nginx.org/ "NGINX | High Performance Load Balancer, Web Server, &amp; Reverse Proxy")) and configure proper authentication there.

Also, you can use the standard `melopt/minion` Docker image for the Web UI if you wish.

You can pass extra options at the end. The most common option is `--mode production` to reduce the log level. The entire option set is available with:

    docker run --rm -e MINION_SOURCE=mysql: melopt/minion webui --help

(we set `MINION_SOURCE` because it is a required configuration. The value `mysql:` is not valid, but it is enough to fool the small check we do for the presence of this configuration).

Our Web UI code is available in the [`bin/admin_app`](https://github.com/melo/docker-minion/blob/master/bin/admin_app) script.

### Worker

To start a worker you would use:

    docker run -d --name minion_worker -e MINION_SOURCE=... \
           -e MINION_PLUGINS=... melopt/minion worker

You can pass extra options at the end. The most common option is `--mode production` to reduce the log level. Two others that might be useful:

* `-j <jobs>`: the number of concurrent jobs to allow.
* `-q <queue>`: which queues to execute jobs from. You can start multiple workers, some of them just for some of the queues to guarantee workers per queue.

The entire option set is available with:

    docker run --rm -e MINION_SOURCE=mysql: melopt/minion worker --help

(we set `MINION_SOURCE` because it is a required configuration. The value `mysql:` is not valid, but it is enough to fool the small check we do for the presence of this configuration).

Our worker code is available in the [`bin/worker_app`](https://github.com/melo/docker-minion/blob/master/bin/worker_app) script.
