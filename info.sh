nargo compile --force && bb gates -b ./target/noir_bigcurve.json

# This is the command I've been using, to then view a flamegraph at localhost:3000:
# You'll need to replace all the paths for nargo, bb, the json file, for whatever they are on your machine.
# And you'll need a recent version of nargo; possibly the one inside aztec-packages.

# ~/git/noir/target/debug/nargo compile && ~/.bb/bb gates_mega_honk -b ./target/noir_bigcurve.json > txt.txt && ~/git/noir/target/debug/noir-profiler gates-flamegraph --artifact-path ./target/noir_bigcurve.json --backend-path ~/.bb/bb --output ./flamegraph --backend-gates-command "gates_mega_honk" && python3 -m http.server --directory "./flamegraph" 3000