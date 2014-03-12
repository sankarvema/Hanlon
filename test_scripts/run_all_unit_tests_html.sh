# Runs all unit tests with HTML output to WEBPATH specified
# You must change webpath to match your

echo "OCCAM_RSPEC_WEBPATH is: $OCCAM_RSPEC_WEBPATH"
echo "OCCAM HOME is: $OCCAM_HOME"
cd $OCCAM_HOME

rspec -c -f h > $OCCAM_RSPEC_WEBPATH/occam_tests.html
