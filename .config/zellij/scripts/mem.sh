#!/bin/bash
vm_stat | awk '/Pages active/{a=$3}/Pages wired/{w=$3}/Pages free/{f=$3}/Pages inactive/{i=$3}/Pages speculative/{s=$3}END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",f);gsub(/\./,"",i);gsub(/\./,"",s);printf "%.0f%%",(a+w)/(a+w+f+i+s)*100}'
