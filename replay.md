# Replay — the canonical solution

Every command that builds the finished course state, in order. No
exploratory / trying commands (`ls`, `pwd`, `git status`, `--help`,
zero-hit searches) — only the ones that produce the final repository.

Copy-paste top to bottom in a fresh session and you end with a clean
repo, the analysis outputs, a filled report, and a seven-commit history.


## 1. Workspace + git

```bash
mkdir work && cd work

echo "Synechocystis sp. PCC 6803" > organism.txt
echo "kingdom: Bacteria"         >> organism.txt
echo "phylum: Cyanobacteria"     >> organism.txt

git init
git add organism.txt
git commit -m "first notes"
```


## 2. Fetch the data

```bash
sudo apt-get update
sudo apt-get install -y wget

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz

gunzip -k GCF_000009725.1_ASM972v1_protein.faa.gz
mv GCF_000009725.1_ASM972v1_protein.faa synechocystis.faa
```


## 3. Ignore the raw FASTA

```bash
echo "*.faa"    >  .gitignore
echo "*.faa.gz" >> .gitignore

git add .gitignore
git commit -m "ignore raw FASTA"
```


## 4. Analysis

```bash
# total proteins
grep -c "^>" synechocystis.faa

# photosystem II family (psbA is annotated "photosystem II q(b) protein")
grep "^>" synechocystis.faa | grep -i "photosystem ii" > psba.txt

# ribosomal proteins
grep "^>" synechocystis.faa | grep -i ribosom > ribosomal.txt

# every protein ID
grep "^>" synechocystis.faa | cut -d' ' -f1 | tr -d '>' > all_ids.txt

# one-line summary
seqkit stats synechocystis.faa

git add psba.txt ribosomal.txt all_ids.txt
git commit -m "analysis: counts and lists"
```


## 5. Report

```bash
cat > report.md <<'EOF'
# Synechocystis sp. PCC 6803

- assembly:        GCF_000009725.1
- source:          NCBI
- total proteins:  3576
- psbA family:     see psba.txt
- ribosomal count: see ribosomal.txt
EOF

git add report.md
git commit -m "first draft of report"
```


## 6. Confirm the history

```bash
git log --oneline --graph --all
```

Expected — seven commits, one clean story:

```
* first draft of report
* analysis: counts and lists
* ignore raw FASTA
* first notes
```


## Extra (Part 6, optional)

```bash
# whole-proteome amino-acid histogram
grep -v "^>" synechocystis.faa | grep -o . | sort | uniq -c | sort -rn

# strip the > from headers with sed instead of tr
grep "^>" synechocystis.faa | sed 's/>//'
```
