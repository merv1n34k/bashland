# bashland

Web-accessible terminals for teaching bash & git intensives.

Browse to bashland.org and get a fresh isolated Docker container with
bash, git, seqkit, samtools and friends. Refresh = brand new session.


## Endpoints

| URL                            | What                                       |
| ------------------------------ | ------------------------------------------ |
| `https://bashland.org/`        | course mode (4-hour guided intensive)      |
| `https://bashland.org/hard`    | hard mode (clone-and-do separate task)     |
| `https://bashland.org/docs`    | searchable command reference (public)      |

Course and hard modes are gated by HTTP basic auth (shared class
password). Docs are public.


## Architecture

    nginx (TLS, auth_basic)
        |
        +-- /        --> ttyd-bashland@course (port 7681)
        |                    --> docker run --rm --network=bashland-egress
        |                          bind: /srv/bashland/course -> /opt/course
        |
        +-- /hard    --> ttyd-bashland@hard   (port 7682)
        |                    --> docker run --rm --network=bashland-egress
        |                          bind: /srv/bashland/hard -> /opt/course
        |
        +-- /docs    --> static files at /opt/bashland/docs/

Both modes use the same image (`bashland-course:latest`); only the
bind-mount source and the per-mode resource caps differ. The container
entrypoint copies `/opt/course/.` into the student's `~/` (excluding
`banner.txt`) and execs an interactive bash.


## Repo layout

    course/              bind-mounted into course-mode containers
      README.md          task brief students see
      banner.txt         shown at session start (not copied to $HOME)
    hard/                bind-mounted into hard-mode containers
      banner.txt         contains the clone URL for the hard task repo
    docker/              Dockerfile + entrypoint + skel/
    nginx/               bashland.conf
    systemd/             ttyd-bashland@.service + per-mode env files
                         bashland-network.service
    scripts/             spawn-session.sh, network-setup.sh, ...
    docs/                static command-reference site
    bootstrap.sh         one-shot installer for a fresh Ubuntu server
    practise.md          instructor playbook (not deployed)
    TODO.md              local-only notes (covered by global gitignore)


## Deploy on a fresh server

Ubuntu 24.04+ (e.g. Hetzner CPX), with sudo:

    sudo apt-get install -y git
    sudo git clone https://github.com/merv1n34k/bashland /opt/bashland
    cd /opt/bashland
    sudo ./bootstrap.sh bashland.org you@example.com 'class-password'

That installs Docker, ttyd, nginx, certbot; builds the course image;
sets up the egress-filtered Docker network; gets a Let's Encrypt cert;
and starts the per-mode systemd services.


## Update a deployed server

    cd /opt/bashland && sudo git pull

    # refresh per-mode bind dirs (bootstrap only seeds them once)
    sudo rsync -av --delete /opt/bashland/course/ /srv/bashland/course/
    sudo rsync -av --delete /opt/bashland/hard/   /srv/bashland/hard/

If `docker/` changed, rebuild and kick running containers:

    sudo docker build --no-cache -t bashland-course:latest /opt/bashland/docker/
    sudo docker ps -q --filter "label=bashland.mode" | xargs -r sudo docker kill


## Per-session resource caps

    course:  256 MB / 0.25 CPU / 24 PIDs / 20 MB max file / 10 min CPU time
    hard:    384 MB / 0.4  CPU / 32 PIDs / 32 MB max file / 15 min CPU time

Global concurrent-container cap: 150.

Containers run with `--cap-drop=ALL` plus the minimum set of caps
needed for `sudo apt-get` (CHOWN, DAC_OVERRIDE, FOWNER, FSETID, SETUID,
SETGID, SETPCAP). Sudoers is locked to `apt-get` only - any other
`sudo` command is denied.


## Hard mode

The hard-mode task lives in a separate repo:
<https://github.com/merv1n34k/bashland-hard>.

Three branches:

- `main`    - task brief, FASTA URL, workflow
- `report`  - `report.md` template (one file only)
- `answers` - troll branch (one file only)

Students discover the branch structure themselves, peek at `report`,
then `git merge --no-ff report` into main to bring the template in
and do the analysis. `true_answers.md` is gitignored.


## License

Distributed under MIT license, see `LICENSE` for more.
