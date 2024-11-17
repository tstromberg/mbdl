#!/bin/bash
for type in elf py python js npm sh dmg macho php ruby rb; do
	$(dirname $0)/mbdl.sh tag $type &
done
wait

for type in elf py js npm sh dmg macho php ruby rb; do
	$(dirname $0)/mbdl.sh file_type $type &
done

wait
