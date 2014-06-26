#!/bin/bash

underline_text=$(tput smul)
green_text=$(tput setaf 2)
normal_text=$(tput sgr0)
blue_text=$(tput setaf 4)
red_text=$(tput setaf 1)
reverse_text=$(tput smso)
pblue_text=$(tput setaf 153)
cyan_text=$(tput setaf 6)

printf "${blue_text}Checking dependencies${normal_text}\n"
echo

if !hash jar 2>/dev/null; then

    printf "${red_text}Could not find jar command line utility\n"
    printf "${red_text}   either jre not install or java path not set\n"
    printf "${red_text}   Please install / configure jre before initiating this script${normal_text}\n"
    exit -1

fi

script_dir=$(pwd)

printf "${blue_text}Downloading Hanlon dependencies${normal_text}\n"
echo

dep_file="hanlon.dep"

if [ ! -f $dep_file ];
then
    printf "${red_text}Script dependency listing file $dep_file does not exists\n"
    printf "${red_text}   Please create the file before initiating this script${normal_text}\n"
   exit -1
fi

OLDIFS=$IFS
IFS=";"

line_cntr=1
while read name url
do
    printf "${cyan_text}[$line_cntr]: downloading $name${normal_text}\n"
    echo
    filename="${url##*/}"
    wget $url
    mv "$filename" ../web/lib
    line_cntr=$[line_cntr+1]
    echo
    echo
done < $dep_file

IFS=$OLDIFS

cd ../core

echo
printf "${blue_text}Compiling directory core to hanlon.core.jar${normal_text}\n"
echo

cat > hanlon.core.README <<EOF
Hanlon application library
hanlon.core.jar
EOF

jar cvf hanlon.core.jar hanlon.core.README

FILESCNT=$(find . -name \*.rb | wc -l)
FILES=$(find . -name \*.rb)
FILECNTR=1

for f in $FILES
do
  printf "Compiling (%-3s of %-4s) -- [%50s]" $FILECNTR $FILESCNT $f
  jrubyc "$f"
  CLASS_FILE=${f//rb/class}
  printf " -- jarify"
  jar uf hanlon.core.jar "$CLASS_FILE"
  printf " -- ${green_text}[OK]${normal_text}\n"
  rm "$CLASS_FILE"
  FILECNTR=$[FILECNTR+1]
done

mv hanlon.core.jar ../script
rm hanlon.core.README

echo
printf "${blue_text}Compiling directory core to hanlon.util.jar${normal_text}\n"
echo

cd ../util

cat > hanlon.util.README <<EOF
Hanlon application library
hanlon.util.jar
EOF

jar cvf hanlon.util.jar hanlon.util.README

FILESCNT=$(find . -name \*.rb | wc -l)
FILES=$(find . -name \*.rb)
FILECNTR=1

for f in $FILES
do
  printf "Compiling (%-3s of %-4s) -- [%50s]" $FILECNTR $FILESCNT $f
  jrubyc "$f"
  CLASS_FILE=${f//rb/class}
  printf " -- jarify"
  jar uf hanlon.util.jar "$CLASS_FILE"
  printf " -- ${green_text}[OK]${normal_text}\n"
  rm "$CLASS_FILE"
  FILECNTR=$[FILECNTR+1]
done

mv hanlon.util.jar ../script
rm hanlon.util.README

cd $script_dir

LIBDIR="../web/lib/"

if [ ! -d "$LIBDIR" ]; then
  mkdir ../web/lib/
fi

cp ../script/hanlon.util.jar ../web/lib/
cp ../script/hanlon.core.jar ../web/lib/

cd ../web

echo
printf "${blue_text}Creating hanlon.war${normal_text}\n"
echo

warble

mv hanlon.war ../script

cd $script_dir

# final touches to the script to address issue  reported by @ jcpowermac as #77
zip -d hanlon.war  WEB-INF/../
zip -d hanlon.war  WEB-INF/../Gemfile.lock
zip -d hanlon.war  WEB-INF/../Gemfile

echo
printf "${green_text}hanlon.war created successfully${normal_text}\n"
echo

