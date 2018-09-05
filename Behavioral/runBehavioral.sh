#!/bin/sh

echo "Calculating behavioral stats and moving files and stuff so you don't have to do it by hand!!!! You're welcome."


if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/*.txt &> /dev/null; then
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/notYetProcessed/
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/*.txt &> /dev/null; then
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/notYetProcessed/
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/*.txt &> /dev/null; then
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/notYetProcessed/
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/*.txt &> /dev/null; then
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/notYetProcessed/
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/notYetProcessed/*.txt &> /dev/null; then
 find experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/notYetProcessed/Duke*.txt >experiments/DNS.01/Scripts/Behavioral/cardsList.txt
 perl experiments/DNS.01/Scripts/Behavioral/getCardsEprime_batch.pl experiments/DNS.01/Scripts/Behavioral/cardsList.txt experiments/DNS.01/Scripts/Behavioral/cardsOut.txt
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/notYetProcessed/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/eprime_txt/
else
 echo "No cards eprime files to analyze. Check DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER."
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/notYetProcessed/*.txt &> /dev/null; then
 find experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/notYetProcessed/NumLS*.txt >experiments/DNS.01/Scripts/Behavioral/numLSList.txt
 perl experiments/DNS.01/Scripts/Behavioral/getNumLSEprime_batch.pl experiments/DNS.01/Scripts/Behavioral/numLSList.txt experiments/DNS.01/Scripts/Behavioral/numLSOut.txt
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/notYetProcessed/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/eprime_txt/
else
 echo "No numLS eprime files to analyze. Check DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER."
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/notYetProcessed/*.txt &> /dev/null; then
 find experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/notYetProcessed/Face*.txt >experiments/DNS.01/Scripts/Behavioral/FNList.txt
 perl experiments/DNS.01/Scripts/Behavioral/getFacenameEprime_batch.pl experiments/DNS.01/Scripts/Behavioral/FNList.txt experiments/DNS.01/Scripts/Behavioral/FNOut.txt
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/notYetProcessed/*output.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/eprime_txt2/
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/notYetProcessed/Face*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/eprime_txt/
else
 echo "No facename eprime files to analyze. Check DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER."
fi

if ls experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/notYetProcessed/*.txt &> /dev/null; then
 find experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/notYetProcessed/Hari*.txt >experiments/DNS.01/Scripts/Behavioral/facesList.txt
 perl experiments/DNS.01/Scripts/Behavioral/getFacesEprime_batch.pl experiments/DNS.01/Scripts/Behavioral/FacesList.txt experiments/DNS.01/Scripts/Behavioral/facesOut.txt
 mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/notYetProcessed/*.txt experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/eprime_txt/
else
 echo "No faces eprime files to analyze. Check DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER."
fi


mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/*.edat2 experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Cards/eprime_edat/ 2> /dev/null
mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/*.edat2 experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/Faces/eprime_edat/ 2> /dev/null
mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/*.edat2 experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/FaceName/eprime_edat/ 2> /dev/null
mv experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/*.edat2 experiments/DNS.01/Data/Behavioral/ALL_RESPONSE_DATA_EVER/NumLS/eprime_edat/ 2> /dev/null

