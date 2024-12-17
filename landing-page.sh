#!/bin/bash
echo "<html><body><h1>$(hostname)</h1></body></html>" > /home/azureuser/page.html
cp /home/azureuser/page.html /var/www/html/index.html
