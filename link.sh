#!/bin/sh
# link.sh - batch hardlink wrapper example
# Edit paths below for your environment, then run directly.
# Uses dirlink.sh for idempotent linking per subdirectory.

/dir/with/dirlink/dirlink.sh /share/Download/src/anime   /share/Download/dst/anime
/dir/with/dirlink/dirlink.sh /share/Download/src/movie   /share/Download/dst/movie
/dir/with/dirlink/dirlink.sh /share/Download/src/tv      /share/Download/dst/tv
