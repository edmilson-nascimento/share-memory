# Memoria compartilhada para programas (share-memory) #

[![N|Solid](https://wiki.scn.sap.com/wiki/download/attachments/1710/ABAP%20Development.png?version=1&modificationDate=1446673897000&api=v2)](https://www.sap.com/brazil/developer.html)

Esta opção trata da necessidade de exportar dados para memororia e importar novamente em outro programa.

~~Quando Deus der coragem~~ Futuramente eu vou melhorar o codigo e mudar com uma boa documentação.

## Necessidade ##
Importar e exportar dados para memoria.

## Tecnologia adotada ##
ABAP usando classe BDC para envio de e-mail.

## Solução ##
Importar o arquivo, via `open data set`, converter em hexadecial e anexo no e-mail.
