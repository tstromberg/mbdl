#!/bin/bash
for type in elf py js npm sh dmg php; do
	./dl.sh $type &
done
wait
