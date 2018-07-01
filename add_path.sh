#!/bin/bash
# add Variants2neoantigen path to ~/.bashrc

echo "Add permission for scripts..."
chmod u+x *.sh runNEO

echo "Add path for Variants2neoantigen tool..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "# add path for Variants2neoantigen tool" >> ~/.bashrc
echo 'export' PATH=\""$DIR:\$PATH"\" >> ~/.bashrc
source ~/.bashrc

echo "Add Variants2neoantigen path to your ~/.bashrc successfully!"
echo "==> Please open a new terminal or run source ~/.bashrc handly before using it."


exit

