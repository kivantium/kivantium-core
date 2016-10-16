CFLAGS = -ansi
TARGET = alice

$(TARGET): simulator/simulator.c
	$(CC) $(CFLAGS) $^ -o $(@)

check: $(TARGET)
	@./alice simulator/test/fib.asm > /dev/null 2> output.txt
	@if diff output.txt simulator/test/fib_answer.txt > /dev/null; then echo "test: OK"; else echo "test: NG"; exit 1; fi

clean:
	rm -f output.txt $(TARGET)
