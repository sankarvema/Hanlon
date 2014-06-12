#/bin/sh

underline_text=$(tput smul)
green_text=$(tput setaf 2)
normal_text=$(tput sgr0)
blue_text=$(tput setaf 4)

script_dir=$(pwd)

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

echo
printf "${green_text}hanlon.war created successfully${normal_text}\n"
echo
