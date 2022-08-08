#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>

int test_fn(void)
{
	return 1337;
}

int (*xom_fn(void))(void)
{
	void *mapped = mmap(0, 100, PROT_READ | PROT_WRITE | PROT_EXEC,
			    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	memcpy(mapped, test_fn, 100);
	mprotect(mapped, 100, PROT_EXEC);
	//memcpy(mapped, test_fn, 100); // write test
	//printf("%d\n", *(int *)mapped); // read test
	return mapped;
}

int main(void)
{
	int fd;
	int result;
	size_t size;

	printf("%d\n", xom_fn()()); // execute test

	return 0;
}
