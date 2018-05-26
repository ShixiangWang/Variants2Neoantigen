#!/bin/bash
# add runNEO path to ~/.bashrc

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "# add path for runNEO tool" >> ~/.bashrc
echo 'export' PATH=\""$DIR:\$PATH"\" >> ~/.bashrc
source ~/.bashrc

echo "Add runNEO path to your ~/.bashrc successfully!"
echo "==> Please open a new terminal or run source ~/.bashrc handly before using it."
exit

