all:
	clang -fmodules schemes.m -o schemes

run: all
	./schemes

format:
	clang-format -i schemes.m