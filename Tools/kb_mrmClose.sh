#!/bin/bash
#
#Kelly Byrne | Silver Lab | UC Berkeley | 2015-10-08

#kb_mrmClose.sh: closes connection to mrMeshMac.app server

#required command-line argument: none
#usage example: kb_mrmClose.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
osascript -e 'quit app "mrMeshMac.app"'