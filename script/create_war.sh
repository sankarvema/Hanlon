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

if !(hash jar 2>/dev/null); then
    printf "${red_text}Could not find jar command line utility\n"
    printf "${red_text}   either jre not install or java path not set\n"
    printf "${red_text}   Please install / configure jre before initiating this script${normal_text}\n"
    exit -1
fi

if !(hash jrubyc 2>/dev/null); then
    printf "${red_text}Could not find jruby compiler\n"
    printf "${red_text}   either jruby not install or jruby environment set properly\n"
    printf "${red_text}   Please install / configure jruby before initiating this script${normal_text}\n"
    exit -1
fi

#ToDo :: Check if all the necessary script files exist
dep_file="hanlon.dep"

if [ ! -f $dep_file ];
then
    printf "${red_text}Script dependency listing file $dep_file does not exists\n"
    printf "${red_text}   Please create the file before initiating this script${normal_text}\n"
   exit -1
fi
#check gemfile, init.rb, hanlon_server.conf log_dir

script_dir=$(pwd)
build_dir="../build"
lib_dir="../web/lib/"
web_dir="../web/"
core_dir="../core"
util_dir="../util"

if [ ! -d "$lib_dir" ]; then
  mkdir $lib_dir 
fi

if [ ! -d "$build_dir" ]; then
  mkdir $build_dir
fi

printf "${blue_text}Downloading Hanlon dependencies${normal_text}\n"
echo

OLDIFS=$IFS
IFS=";"

line_cntr=1
while read name url
do
    printf "${cyan_text}[$line_cntr]: downloading $name${normal_text}\n"
    filename="${url##*/}"
    wget -nv $url
    mv "$filename" $lib_dir
    line_cntr=$[line_cntr+1]
    echo
done < $dep_file

IFS=$OLDIFS

cd $core_dir

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

mv hanlon.core.jar $build_dir
rm hanlon.core.README

echo
printf "${blue_text}Compiling directory core to hanlon.util.jar${normal_text}\n"
echo

cd $util_dir

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

mv hanlon.util.jar $build_dir
rm hanlon.util.README

cd $script_dir

cp $build_dir/hanlon.util.jar $lib_dir
cp $build_dir/hanlon.core.jar $lib_dir
cp ../Gemfile* $web_dir

cd $web_dir

echo
printf "${blue_text}Creating hanlon.war${normal_text}\n"
echo

warble -q

mv hanlon.war $build_dir

echo
printf "${blue_text}Cleaning temporary files{normal_text}\n"

rm -f $web_dir/Gemfile*
rm -rf $web_dir/tmp/

cd $script_dir

#ToDo :: Sanity check on the war file created

echo
printf "${green_text}hanlon.war created successfully at $build_dir ${normal_text}\n"

echo