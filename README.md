# MD5-ASM64
 Tentative d'implémentation de md5 en ASM x64 intel (spoiler alert : fail)
 Je segfault sans arrêt et je n'arrive pas à comprendre pourquoi...

 # Démarrer le programme : 
 `nasm -f elf64 -o md5.o md5.asm && ld -o md5 md5.o`\
 `./md5`