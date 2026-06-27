# Instructor's playbook - BashLand 4-hour intensive

For me. Not deployed. Not visible to students.

The student opens a tab. They get a shell and a `README.md` that says
nothing more than what's needed - the organism, what to find, what to
hand in. No commands. No hints. They poke, they guess, they ask. We
guide.

This file is the walk-through I follow while the class works. The
sections aren't strict hours - some classes need more time on bash,
some on git. Total target: 4 hours including breaks.


## 1. bash basics (~45 min)

Themes: where am I, what is here, how do I look at a file, how do I
make something.

Let them try first; demo when stuck:

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

Make files, redirect, append.

`echo` prints what you give it back to the terminal:

    echo "Synechocystis sp. PCC 6803"

The `>` symbol *redirects* the output of a command into a file instead
of the screen. The file is created if it doesn't exist, overwritten if
it does:

    echo "Synechocystis sp. PCC 6803" > organism.txt

`>>` is the same but *appends* to the file rather than overwriting it:

    echo "kingdom: Bacteria" >> organism.txt
    cat organism.txt

`touch` creates an empty file (or updates its modification time):

    touch notes.txt

Page through files:

    less organism.txt                # q to quit

Inspection by line count:

    wc -l organism.txt
    head -n 1 organism.txt
    tail -n 1 organism.txt

At this point they have a workspace and a feel for the shell. They have
not started the actual task yet, but they have a directory worth
tracking.


## 2. git intro (~45 min)

Themes: init / status / add / commit / log.

Set up version control BEFORE doing real work - real research projects
work this way. From the `work` directory:

    git init
    git status                       # untracked files appear

Stage and commit what they already made:

    git add organism.txt notes.txt
    git status                       # now staged
    git commit -m "first notes on synechocystis"
    git log
    git log --oneline                # compact view

Make a change, see what git notices:

    echo "phylum: Cyanobacteria" >> organism.txt
    git status                       # modified
    git diff                         # see the change
    git add organism.txt
    git commit -m "add phylum"
    git log --oneline

Introduce `.gitignore` early - they will need it the moment they
download the FASTA. Explain the why; show the how when they actually
have a file to ignore.

What they take away from this section:

    init - status - add - commit - log - diff


## 3. fetch and play with data (~60 min)

Themes: sudo, package management, downloading, decompressing.

They will quickly hit "wget: command not found". Good. Walk them
through `sudo`:

    sudo apt-get update
    sudo apt-get install -y wget

Show sudo is limited:

    sudo cat /etc/shadow             # "not permitted"
    sudo bash                        # "not permitted"

Have them find the URL on NCBI themselves (organism: Synechocystis sp.
PCC 6803, assembly GCF_000009725.1). The full URL:

    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz

Download:

    wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz
    ls -lh
    file GCF_000009725.1_ASM972v1_protein.faa.gz

**Important git moment:** before committing anything, tell git to
ignore the FASTA (it is too large):

    echo synechocystis.faa.gz  >  .gitignore
    echo synechocystis.faa     >> .gitignore
    git add .gitignore
    git commit -m "ignore raw FASTA"

Decompress and rename:

    gunzip -k GCF_000009725.1_ASM972v1_protein.faa.gz
    mv GCF_000009725.1_ASM972v1_protein.faa synechocystis.faa

Confirm git is silent about the FASTAs:

    git status                       # clean, despite the big file

Inspect the contents:

    head synechocystis.faa
    tail -n 5 synechocystis.faa
    less synechocystis.faa


## 4. analysis, report, commit (~75 min)

Themes: grep, pipes, cut, tr, redirection, seqkit. Introduce each
tool with a small demo before composing them.


### grep - find matching lines

`grep` prints lines from a file that match a pattern.

    grep ">" synechocystis.faa | head     # any line containing >

To match only lines that START with `>`, anchor with `^`:

    grep "^>" synechocystis.faa | head    # only FASTA headers

There is one header per sequence. Count them with `-c`:

    grep -c "^>" synechocystis.faa        # first deliverable: total proteins


### pipes - chain commands together

The `|` symbol sends the output of one command into the next as input.
Two-stage filter: headers first, then case-insensitive match:

    grep "^>" synechocystis.faa | grep -i ribosom | head


### save output - they already know `>` from section 1

Combine grep with the redirect they already met. Save the ribosomal
list and commit it:

    grep "^>" synechocystis.faa | grep -i ribosom > ribosomal.txt
    wc -l ribosomal.txt
    git add ribosomal.txt
    git commit -m "ribosomal list"

Try psbA the same way - and run into the gotcha:

    grep "^>" synechocystis.faa | grep -i psba > psba.txt
    wc -l psba.txt                         # 0 hits!

(`psba` returns nothing because the annotation labels the protein
"photosystem II q(b) protein". This is a useful biology vs naming
moment. Have them broaden the search; commit whatever they end up with.)

    git add psba.txt
    git commit -m "psba family attempt"


### cut - pick fields from a line

`cut` extracts columns. `-d` sets the delimiter (default: tab), `-f`
picks which field(s):

    echo "apple,banana,cherry" | cut -d, -f1      # apple
    echo "apple,banana,cherry" | cut -d, -f2,3    # banana,cherry

In a FASTA header, the ID is the first word - everything before the
first space. So:

    head -n 1 synechocystis.faa | cut -d' ' -f1   # >WP_010871214.1


### tr - replace or delete characters

`tr` translates characters. With `-d` it deletes them.

    echo "hello" | tr -d 'l'              # heo
    echo ">WP_123.1" | tr -d '>'          # WP_123.1


### compose: extract all protein IDs

Now combine everything into the classic chain:

    grep "^>" synechocystis.faa | cut -d' ' -f1 | tr -d '>' > all_ids.txt
    wc -l all_ids.txt
    head all_ids.txt
    git add all_ids.txt
    git commit -m "all protein ids"

Walk through each stage with them:

1. `grep "^>" synechocystis.faa` - keep only header lines
2. `| cut -d' ' -f1` - keep only the first space-delimited word (the ID + `>`)
3. `| tr -d '>'` - drop the `>` character
4. `> all_ids.txt` - save to file


### seqkit - the bioinformatics shortcut

`seqkit` reads FASTA directly. One line, full summary:

    seqkit stats synechocystis.faa
    seqkit stats synechocystis.faa.gz     # works on the gzipped file too

This is the payoff for learning the bash chain first - they now see
what a bio-specific tool gives you "for free" and recognise the
difference.


### report.md

Write up findings. Use a heredoc to demo a clean starter:

    cat > report.md <<'EOF'
    # Synechocystis sp. PCC 6803

    - assembly: GCF_000009725.1
    - source: NCBI
    - protein count:   <fill in>
    - psbA-family:     <see psba.txt>
    - ribosomal count: <see ribosomal.txt>
    EOF

They fill in. Commit:

    git add report.md
    git commit -m "first draft of report"
    git log --oneline


## 5. wrap up (~15 min)

What "done" looks like:

    git log --oneline --graph --all

That should read like the story of the session - one commit per logical
step. `.gitignore` keeping the FASTA out. `report.md` answering the
brief.

Quick demo of a branch (if time):

    git switch -c try-different-keyword
    grep '^>' synechocystis.faa | grep -i photo > photo.txt
    git add photo.txt
    git commit -m "explore photosynthesis-related"
    git log --oneline --graph --all
    git switch main
    ls                               # photo.txt is gone here

Merge if they want:

    git merge try-different-keyword
    git log --oneline --graph --all

Mention `/docs` reference at <https://bashland.org/docs>.

Point students who finish early at <https://bashland.org/hard> - the
hard mode lives in a separate GitHub repo with branches they have to
discover.


## Where students will trip

1. Trying `sudo bash` or `sudo cat`. Tell them sudo is locked to
   `apt-get` and that's intentional.
2. Forgetting `^` in `grep` - they find the substring inside sequence
   bodies instead of in headers. Demo both.
3. `grep -i psba` returns zero hits because the RefSeq annotation
   labels the protein as "photosystem II q(b) protein". This is
   educational - the gene-symbol -> protein-name mapping is non-trivial.
4. `git add .` after downloading the FASTA - commits the FASTA. Show
   `git restore --staged <file>` and reinforce the `.gitignore` habit.
5. Tab closing. Refresh = new container = work gone. Drill this early.
   (They can still re-clone the FASTA from NCBI; their analysis files
   are also lost.)
