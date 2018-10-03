objs := header.o main.o
out := soundtest.nes

all: $(out)

clean:
	rm -f $(objs) $(out)

.PHONY: all clean

# Assemble

%.o: %.s
	ca65 $< -o $@

main.o: main.s defs.s
header.o: header.s

# Link

soundtest.nes: link.x $(objs)
	ld65 -C link.x $(objs) -o $@
