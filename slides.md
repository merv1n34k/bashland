---
marp: true
theme: default
paginate: true
size: 16:9
header: 'BashLand — bash & git intensive'
footer: 'bashland.org'
style: |
  section {
    font-family: 'Helvetica', 'Arial', sans-serif;
    font-size: 26px;
  }
  code, pre {
    font-family: 'ui-monospace', 'Menlo', 'Consolas', monospace;
    font-size: 22px;
  }
  h1 { font-size: 44px; }
  h2 { font-size: 34px; }
  .lead h1 { font-size: 60px; }
  section.lead { text-align: center; }
---

<!-- _class: lead -->

# BashLand

A 4-hour intensive on bash & git
using a real bioinformatics dataset

---

<!-- _class: lead -->

# Hi, I'm your instructor

<br>

**[placeholder — instructor: a few words about yourself here.
who you are, why you love bash & git, one sentence about the research
you use them for]**

---

## What a computer actually is

You use a computer through **windows, icons, and clicks** — the
graphical interface, GUI.

The GUI is not the computer.
It's one **friendly, opinionated wrapper** over the real thing.

Someone decided:

- which buttons you get to press
- which folders are visible
- which commands are hidden

The computer itself doesn't care about any of that.

---

## To talk to it directly, we use the shell

A **shell** is a text-based interface that lets you *instruct* the
computer directly. You type what you want, the computer does it.

- no button was drawn — you don't need one
- no menu decided what's possible — everything is
- no click was tracked — just your keystrokes

Today you'll leave the GUI behind and speak to the machine directly.

---

## Two kinds of instructions

Today you'll learn two languages:

<br>

| **bash** | **git** |
| :---: | :---: |
| instructions that **drift reality** | instructions that **travel through time** |
| do it now: create, move, delete | snapshot the past, jump between versions |
| the *present* | the *history* |

<br>

Both are text. Both live in the same shell.
Together they cover 90% of what a working scientist or engineer types
in a day.

---

## What you will leave with

<br>

By the end of today you can:

1. **navigate and control** any Linux/Mac shell
2. **track your files** and their changes with git
3. **fetch, inspect, and process** a real biological dataset
4. **write a short report** and commit it as part of a clean git
   history

<br>

You will not be a bash wizard by dinner. You will be someone who can
sit down at any terminal and not panic.

---

## For hardcore enthusiasts

If you finish early, or if today is too gentle, there is a
**hard mode** you can attempt any time:

<br>

    https://bashland.org/hard

<br>

A separate task in a real GitHub repository, no hand-holding, more
sophisticated git workflow. Come back to it after the class.

---

## Today's subject: Synechocystis sp. PCC 6803

A tiny **cyanobacterium** — a photosynthetic bacterium.

- one of the first bacteria to be **fully sequenced** (1996)
- textbook model for how **oxygenic photosynthesis** works
- the ancestral relative of **plant chloroplasts**
- widely engineered for **biofuels** and **biopharmaceuticals**

Genome: ~3.6 Mbp, one circular chromosome + plasmids.
Encodes ~3,600 proteins.

Today you'll analyze its **proteome** — the list of every protein it
knows how to make.

---

## What is a FASTA file?

A plain-text format for **DNA, RNA, or protein sequences**.

```
>WP_010871214.1 photosystem II q(b) protein [Synechocystis]
MTATLERRESQSLWKRFCEWITSTENRLYIGWFGVLMIPTLLTATSVFIIAFIAAPPV
LYGNNIISGAIIPTSAAIGLHFYPIWEAASLDEWLYNGGPYQMIVCHFLLGVACYMGR
...

>WP_010871215.1 biosynthetic arginine decarboxylase [Synechocystis]
MSTNLPSKPLLQLAKSLSAAVLAFPHPQGYLNQFEQDDLFLQMLRALQNQFHNVDIAA
...
```

- a header line starts with `>` — sequence ID + description
- following lines are the sequence itself
- **one `>` line = one protein**

That last fact is the trick to counting.

---

<!-- _class: lead -->

# Part 1 — bash basics

instructions that drift reality

---

## Where am I?

```
pwd                # print working directory
```

You see something like:

```
/home/student
```

That's your **home directory**. Everything you make today lives here.
Refresh the browser tab and everything is wiped.

---

## What is here?

```
ls                 # list files
ls -l              # long format: perms, size, modified
ls -la             # also hidden files (start with .)
```

The `-l` and `-a` are **flags**. Flags modify a command.
Almost every command has a `--help` flag:

```
ls --help
```

---

## Move around

```
mkdir work         # make a directory
cd work            # go into it
pwd                # confirm

cd ..              # up one level
cd work            # back in
cd ~               # home
cd -               # previous location
```

`~` = shorthand for your home directory.
`..` = the directory above the current one.

---

## Make files

```
touch notes.txt              # empty file
echo "hello"                 # prints "hello"
echo "hello" > organism.txt  # writes to a file
echo "world" >> organism.txt # appends to a file
cat organism.txt             # show contents
```

- `>` **overwrites** a file
- `>>` **appends**

These little arrows are the workhorse of the whole shell.

---

## Look at files

```
cat  README.md               # small: dump to screen
less README.md               # long: pager. q to quit.
head README.md               # first 10 lines
tail README.md               # last 10 lines
head -n 3 README.md          # first 3
wc   README.md               # count lines, words, bytes
wc -l README.md              # only lines
```

Try `cat README.md` now — the task for today is written there.

---

<!-- _class: lead -->

# Part 2 — git intro

instructions that travel through time

---

## Why version control?

- **undo** any mistake, all the way back
- see **what changed** and when
- **compare** two versions of a file
- try an idea on a **branch** without losing the working version

<br>

Real research and real code both use git.
Today you'll use it too, from the first file you create.

---

## Initialize a repo

Inside your `work` directory:

```
git init              # turn this dir into a repo
git status            # what's tracked, what isn't
```

`git status` is the command you'll type most often.
Type it after **every** other git command until it feels boring.

---

## Track a file

```
git add organism.txt        # stage
git status                  # now "staged"
git commit -m "first notes" # save a snapshot
git log                     # see history
git log --oneline           # compact
```

`add` puts a file into the **staging area**.
`commit` snapshots whatever is staged.

Together they mean: *"take a picture of this state, label it, keep it
forever."*

---

## See what changed

```
echo "phylum: Cyanobacteria" >> organism.txt
git status                  # "modified"
git diff                    # show me the change

git add organism.txt
git commit -m "add phylum"
git log --oneline
```

- `git status` = *what* changed
- `git diff` = *what the change actually is*

---

<!-- _class: lead -->

# Part 3 — fetch the data

grep meets wget

---

## The task is in the README

You already saw the task with `cat README.md`.
Somewhere in there is a **URL** — the location of the Synechocystis
protein FASTA on NCBI.

Rule of thumb for the whole day:

> **never type a long URL by hand.**

If a computer put it in a file, ask the computer to read it back.

---

## Meet grep — find matching lines

`grep` prints lines that match a pattern.

```
grep https README.md
```

That shows every line containing "https" — the URL lines.

Now extract *just* the URL, no surrounding text:

```
grep -o 'https://[^ ]*' README.md
```

- `-o` = **only** the matching part
- `[^ ]*` = any characters except a space (= the URL only)

---

## Use grep's output as wget's input

Store it in a variable:

```
URL=$(grep -o 'https://[^ ]*\.faa\.gz' README.md)
echo $URL
```

`$(...)` runs a command and hands you its output.
Now use it:

```
wget "$URL"
```

**Zero typing of the long URL.** The computer read it, remembered it,
handed it to `wget`.

---

## Install what you need with sudo

You'll notice `wget` might not be there yet:

```
wget: command not found
```

Install it — the shell knows the trick:

```
sudo apt-get update
sudo apt-get install -y wget
```

`sudo` runs a single command as **root** (the administrator).
Here it's locked to `apt-get` only. Try `sudo cat` — it refuses.

---

## Unpack the data

```
ls -lh                    # ~700 KB, compressed .gz

file GCF_..._protein.faa.gz    # what is this?

gunzip -k GCF_..._protein.faa.gz   # -k keeps the .gz

mv GCF_..._protein.faa synechocystis.faa

ls -lh                    # ~1.4 MB, uncompressed
```

Rename because life is too short to type
`GCF_000009725.1_ASM972v1_protein.faa` fifty times.

---

## Tell git to ignore the big file

Before touching git again:

```
echo synechocystis.faa    >  .gitignore
echo synechocystis.faa.gz >> .gitignore

git add .gitignore
git commit -m "ignore raw FASTA"

git status                # clean, even with the big file present
```

`.gitignore` = one pattern per line. Files matching are hidden from
git commands.

---

<!-- _class: lead -->

# Part 4 — the analysis

more grep, plus pipes, cut, tr, seqkit

---

## Count proteins with grep

Every protein starts with a `>`. So the total protein count is the
number of `>` lines:

```
grep "^>" synechocystis.faa | head    # look at some
grep -c "^>" synechocystis.faa        # count them
```

- `^` in the pattern = *"start of the line"*
- `-c` = *count instead of print*

Your first real number. Write it down for the report.

---

## Chain commands with pipes

`|` sends the output of one command as the input of the next.

```
grep "^>" synechocystis.faa | grep -i ribosom | head
```

Left to right:

1. keep header lines
2. of those, keep the ones mentioning "ribosom" (case-insensitive)
3. show the first 10

This is the shape of most bash work: **short tools chained together.**

---

## Save your findings

Use `>` from Part 1:

```
grep "^>" synechocystis.faa | grep -i ribosom > ribosomal.txt
wc -l ribosomal.txt
```

Commit as you go:

```
git add ribosomal.txt
git commit -m "ribosomal list"
```

Try the same for psbA. You may hit a **naming gotcha** — the RefSeq
annotation labels it *photosystem II q(b) protein*. Real biology, not
a bash problem.

---

## cut — pick columns

```
echo "apple,banana,cherry" | cut -d, -f1        # apple
echo "apple,banana,cherry" | cut -d, -f2,3      # banana,cherry
```

- `-d` = delimiter
- `-f` = field(s)

A FASTA header's ID is the **first space-separated word**:

```
head -n 1 synechocystis.faa | cut -d' ' -f1     # >WP_010871214.1
```

---

## tr — replace or delete characters

```
echo "hello" | tr -d 'l'          # heo   (delete l's)
echo ">WP_123.1" | tr -d '>'      # WP_123.1
```

- `-d` = delete these characters

Small, sharp, single-purpose.

---

## Compose: extract every protein ID

```
grep "^>" synechocystis.faa \
  | cut -d' ' -f1 \
  | tr -d '>' \
  > all_ids.txt

wc -l all_ids.txt
head all_ids.txt
```

1. keep header lines
2. keep only the first word (ID with `>`)
3. drop the `>`
4. save to file

Commit it.

---

## seqkit — the bioinformatics shortcut

`seqkit` speaks FASTA natively:

```
seqkit stats synechocystis.faa           # one-line summary
seqkit stats synechocystis.faa.gz        # works on the .gz too
```

Output:

```
file             format  type     num_seqs    sum_len  min_len  avg_len  max_len
synechocystis..  FASTA   Protein     3,576  1,117,688       26    312.6    4,199
```

Everything you just spent an hour computing, in one line.
Now you know **why** bio tools exist — and what they're really doing.

---

## Write `report.md`

Use a heredoc to make a starter:

```
cat > report.md <<'EOF'
# Synechocystis sp. PCC 6803

- assembly:        GCF_000009725.1
- source:          NCBI
- total proteins:  <fill in>
- psbA family:     <see psba.txt>
- ribosomal count: <see ribosomal.txt>
EOF
```

Fill in the numbers, then:

```
git add report.md
git commit -m "first draft of report"
```

---

<!-- _class: lead -->

# Part 5 — wrap up

what "done" looks like

---

## The story of the session

```
git log --oneline --graph --all
```

Should read like a small narrative:

```
* 9f2a1c  first draft of report
* 8c4b3d  all protein ids
* 7a1e5c  ribosomal list
* 6d3f8e  psba family attempt
* 5f2a1c  ignore raw FASTA
* 4c4b3d  add phylum
* 3a1e5c  first notes
```

One commit per logical step. That's the goal.

---

## Bonus: try a branch

```
git switch -c try-photo
grep "^>" synechocystis.faa | grep -i photo > photo.txt
git add photo.txt
git commit -m "explore photosynthesis-related"

git switch main
ls                      # photo.txt is gone here

git merge try-photo     # bring it in
```

Branches let you try ideas without disturbing what works.

---

## Where students trip

- **`sudo bash` or `sudo cat` fails** — `sudo` here is locked to
  `apt-get`. By design.
- **forgetting `^` in `grep`** — you match inside sequence bodies
  instead of headers. Slow, wrong.
- **`grep -i psba` returns 0** — annotation says "q(b) protein". A
  naming gotcha, not a bash bug.
- **`git add .` after downloading the FASTA** — commits the FASTA.
  Fix: `.gitignore`.
- **closing the tab wipes everything** — refresh = new container.

---

## Resources

<br>

- **command reference**: <https://bashland.org/docs>
- **harder challenge**: <https://bashland.org/hard>
- **source & docs**: <https://github.com/merv1n34k/bashland>
- **hard mode task**: <https://github.com/merv1n34k/bashland-hard>

<br>

Questions? Good.

---

<!-- _class: lead -->

# Appendix — SSH

not part of BashLand, but useful when you have your own server

---

## What is SSH?

**S**ecure **Sh**ell — the standard way to open a shell on a remote
computer over the internet.

- encrypted end-to-end
- authenticated (password or key)
- works from any OS

<br>

Placeholder server for the demo:

```
203.0.113.42
```

(real IP will be shared separately.)

---

## SSH on **Windows**

Windows 10 (1809+) and Windows 11 include OpenSSH by default.

Open **PowerShell** or **Command Prompt**:

```
ssh user@203.0.113.42
```

If "command not found":

**Settings** → **Apps** → **Optional features** → **Add a feature**
→ search **OpenSSH Client** → install.

Or use **PuTTY** (putty.org) — GUI alternative.

---

## SSH on **macOS**

macOS ships with OpenSSH. Open **Terminal.app**
(`Applications` → `Utilities` → `Terminal`).

```
ssh user@203.0.113.42
```

That's it. No install needed.

<br>

Tip: iTerm2 (iterm2.com) is a nicer terminal. Optional.

---

## SSH on **Linux**

You almost certainly already have it. Test:

```
which ssh
```

If missing (rare):

```
sudo apt-get install -y openssh-client   # Debian, Ubuntu
sudo dnf install -y openssh-clients      # Fedora
```

Connect:

```
ssh user@203.0.113.42
```

---

## First connection

The first time you connect you'll see:

```
The authenticity of host '203.0.113.42' can't be established.
ED25519 key fingerprint is SHA256:xxxxx.
Are you sure you want to continue connecting? (yes/no)
```

Type `yes` and Enter. Server is remembered so it warns you if it ever
changes.

Then enter your password.

To disconnect later: type `exit`.
