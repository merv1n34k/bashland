# Welcome                                 # Привіт!


You will learn how to navigate and        На цьому курсі ти навчишся переміщуватись
control the system, how to track files    та керувати системою, відстежувати
and changes, and try yourself with        файли та зміни, і спробуєш себе
reporting a bioinformatics analysis.      у складанні звіту з біоінформа-
                                          тичного аналізу.


## Tasks                                  ## Завдання


1. Set up a workspace and a git           1. Налаштувати робочий простір
   repository.                               і git-репозиторій.

2. Fetch the Synechocystis sp. PCC 6803   2. Завантажити білковий FASTA
   protein FASTA from NCBI (URL below).      для Synechocystis sp. PCC 6803 з
                                             NCBI (URL нижче).

3. Count proteins, find specific          3. Підрахувати білки, знайти
   families (psbA, ribosomal), extract       конкретні родини (psbA, рибо-
   sequence IDs.                             сомальні), отримати ідентифі-
                                          катори послідовностей.

4. Write `report.md` with your            4. Записати свої результати у
   findings.                                 `report.md`.

5. Commit your work cleanly, with the     5. Зберегти прогрес роботи, без
   raw FASTA gitignored.                     зайвих FASTA файлів у `.gitignore`.


## Data / Дані


Protein FASTA (Synechocystis sp. PCC 6803, assembly GCF_000009725.1):

https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/725/GCF_000009725.1_ASM972v1/GCF_000009725.1_ASM972v1_protein.faa.gz

Extract it and download in two commands:

    URL=$(grep -o 'https://[^ ]*\.faa\.gz' README.md)
    wget "$URL"


## Resources                              ## Ресурси


- https://bashland.org/docs               - https://bashland.org/docs
  command reference                         довідник команд

- https://bashland.org/hard               - https://bashland.org/hard
  harder challenge                          курс для сильних духом
