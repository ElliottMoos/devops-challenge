#! /bin/bash
set -e

if curl -s --head --request GET $1 | grep "200 OK" > /dev/null; then
	echo "Lendflow Challenge web service is UP!"
else
	echo "Lendflow Challenge web service is NOT READY or DOWN:("
fi