# Instructor's playbook - BashLand 4-hour intensive

For me. Not deployed. Not visible to students.

The student opens a tab. They get a shell and a `README.md` that says
nothing more than what's needed - the organism, what to find, what to
hand in. No commands. No hints. They poke, they guess, they ask. We
guide.

This file is the walk-through I follow while the class works. Each
section ends with the commands they should have produced by the end of
that hour.


## Hour 1 - finding your way around (~45 min)

Themes: where am I, what is here, how do I look at a file, how do I
make something.

Bash basics (let them try first; demo when stuck):

    pwd                              # /home/student
    ls
    ls -la
    cat README.md                    # they see the brief

Move around:

    cd ~
    mkdir work
    cd work
    cd ..
    cd work
    pwd

Make files, redirect, append:

    touch notes.txt
    echo "Synechocystis sp. PCC 6803" > organism.txt
    echo "kingdom: Bacteria" >> organism.txt
    cat organism.txt

Page through files:

    less organism.txt                # q to quit

Inspection by line count:

    wc -l organism.txt
    head -n 1 organism.txt
    tail -n 1 organism.txt

At this point they have a workspace and a feel for the shell. They have
not started the actual task yet.


## Hour 2 - reach the outside (~45 min)

Themes: package management, downloading from the internet,
decompressing.

They will quickly hit "no wget". Good. Walk them through `sudo`:

    sudo apt-get update
    sudo apt-get install -y wget

Show them sudo is limited:

    sudo cat /etc/shadow             # "not permitted"

Now wget. Have them find the URL on NCBI themselves
(GCF_000009725.1_ASM972v1). The full URL:

    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz

Download:

    wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz
    ls -lh
    file GCF_000009725.1_ASM972v1_protein.faa.gz

Decompress, rename:

    gunzip -k GCF_000009725.1_ASM972v1_protein.faa.gz
    mv GCF_000009725.1_ASM972v1_protein.faa synechocystis.faa
    ls -lh


## Hour 3 - the analysis (~60 min)

Themes: grep / pipes / cut / tr / redirection / seqkit.

Take a look:

    head synechocystis.faa
    tail -n 5 synechocystis.faa
    less synechocystis.faa

Count proteins (this is the first deliverable):

    grep -c '^>' synechocystis.faa

psbA family - photosystem II reaction center:

    grep '^>' synechocystis.faa | grep -i psba
    grep '^>' synechocystis.faa | grep -ic psba
    grep '^>' synechocystis.faa | grep -i psba > psba.txt

Ribosomal proteins:

    grep '^>' synechocystis.faa | grep -i ribosom | head
    grep '^>' synechocystis.faa | grep -i ribosom > ribosomal.txt
    wc -l ribosomal.txt

Extract bare protein IDs (cut, tr, redirection - the classic chain):

    grep '^>' synechocystis.faa | cut -d' ' -f1 | tr -d '>' | head
    grep '^>' synechocystis.faa | cut -d' ' -f1 | tr -d '>' > all_ids.txt
    wc -l all_ids.txt

One-line summary with seqkit:

    seqkit stats synechocystis.faa

Write up findings - they make `report.md` themselves. Demo a starter
with `cat <<EOF`:

    cat > report.md <<'EOF'
    # Synechocystis sp. PCC 6803

    - assembly: GCF_000009725.1
    - source: NCBI
    - protein count: <fill in>
    - psbA family: <count, see psba.txt>
    - ribosomal: <count, see ribosomal.txt>
    EOF


## Hour 4 - git (~45 min + buffer)

Themes: init / status / add / commit / log / diff / branch / merge /
gitignore.

In the same `work` directory:

    git init
    git status
    git add organism.txt notes.txt
    git commit -m "first notes on synechocystis"
    git log

The big FASTA must NOT be committed. Show .gitignore:

    echo synechocystis.faa     >  .gitignore
    echo synechocystis.faa.gz  >> .gitignore
    git add .gitignore
    git commit -m "ignore raw FASTA files"

Commit the analysis outputs:

    git add psba.txt ribosomal.txt all_ids.txt report.md
    git commit -m "analysis: counts and id lists"
    git log --oneline

Branch for an experiment:

    git switch -c try-different-keyword
    grep '^>' synechocystis.faa | grep -i photo > photo.txt
    git add photo.txt
    git commit -m "explore photosynthesis-related"
    git log --oneline --graph --all

Back to main:

    git switch main
    ls                                # photo.txt is gone

Merge if they want it:

    git merge try-different-keyword
    git log --oneline --graph --all


## What "done" looks like

A `git log --oneline --graph --all` that reads like the story of the
session. `.gitignore` keeping the FASTA out. `report.md` answering the
brief.


## Where students will trip

1. Trying `sudo bash` or `sudo cat`. Tell them sudo is locked to
   apt-get and that's intentional.
2. Forgetting `^` in grep and finding the substring inside sequences
   instead of in headers. Demo with and without.
3. `git add .` after downloading the FASTA - commits the FASTA.
   Walk them through `git reset HEAD synechocystis.faa` and then the
   .gitignore approach.
4. Tab closing. Refresh = new container = work gone. Drill this early.


## Hard mode

For students who finish early or want it harder, point them at
<https://bashland.org/hard>. The README is even drier - just the
organism name and the artifacts to produce (report.md, analyze.sh,
clean git history, reproducible). They have to design a shell script
that runs the analysis end to end, with functions.
