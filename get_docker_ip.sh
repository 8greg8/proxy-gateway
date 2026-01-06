#!/bin/bash

# Source - https://stackoverflow.com/a
# Posted by WouterD, modified by community. See post 'Timeline' for change history
# Retrieved 2025-12-02, License - CC BY-SA 4.0

docker inspect \
  -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cntlm-gss
