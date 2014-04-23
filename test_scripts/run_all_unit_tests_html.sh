# Runs all unit tests with HTML output to WEBPATH specified
# You must change webpath to match your

echo "HANLON_RSPEC_WEBPATH is: $HANLON_RSPEC_WEBPATH"
echo "HANLON HOME is: $HANLON_HOME"
cd $HANLON_HOME

rspec -c -f h > $HANLON_RSPEC_WEBPATH/hanlon_tests.html
