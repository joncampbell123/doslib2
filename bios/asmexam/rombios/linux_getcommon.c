/* common capture code. do NOT compile as standalone! */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/vfs.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <limits.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>

static int mem_fd = -1;
static unsigned char *ROM;

/* we really only care about whether at least 64KB is available.
 * if more than 4GB is present then clamp return value to 4GB */
static size_t freespace() {
	unsigned long long ttl;
	struct statfs sfs;

	if (statfs(".",&sfs)) {
		fprintf(stderr,"Cannot statfs() current directory %s\n",strerror(errno));
		return 0;
	}

	ttl  = (unsigned long long)sfs.f_bsize;
	if (geteuid() == 0)					/* root */
		ttl *= (unsigned long long)sfs.f_bfree;
	else
		ttl *= (unsigned long long)sfs.f_bavail;	/* non-root */

	if (ttl >= 0xFFFFFFFFULL)
		return ~((size_t)0);

	return (size_t)ttl;
}

static void waitforenter() {
	int c;

	do {
		c=fgetc(stdin);
		if (c < 0) return;
	} while (!(c == 13 || c == 10));
}

int main() {
	unsigned long long segmnt;
	char ppath[PATH_MAX];
	struct stat st;
	char tmp[64];
	int fd;

	if ((mem_fd = open("/dev/mem",O_RDONLY)) < 0) {
		fprintf(stderr,"Unable to open /dev/mem, %s\n",strerror(errno));
		return 1;
	}
	if (fstat(mem_fd,&st)) {
		fprintf(stderr,"Unable to stat opened /dev/mem handle, %s\n",strerror(errno));
		return 1;
	}
	if (!S_ISCHR(st.st_mode)) {
		fprintf(stderr,"/dev/mem is NOT character device\n");
		return 1;
	}

	/* NTS: This code assumes you are compiling with _FILE_OFFSET_BITS == 64 so that
	 *      on 32-bit systems the limitations of the original mmap() call do not interfere
	 *      with our attempt here */
	ROM = mmap(NULL,ROM_size,PROT_READ,MAP_SHARED,mem_fd,ROM_offset);
	if (ROM == MAP_FAILED) {
		fprintf(stderr,"Unable to mmap ROM\n");
		return 1;
	}

	printf(HELLO);
	printf("Press ENTER to start\n");
	waitforenter();

	/* write it out */
	for (segmnt=ROM_offset;segmnt < (ROM_offset+(unsigned long long)ROM_size);segmnt += (unsigned long long)ROM_blocksize) {
		while (freespace() < (66UL << 10UL)) {
			if (getcwd(ppath,sizeof(ppath)) == NULL) {
				fprintf(stderr,"Unable to get current directory\n");
				return 1;
			}

			/* Linux counts the mountpoint as being in use if a file is open there or
			 * a program has it as it's current working directory. so to allow the user
			 * to remove the floppy (or whatever) we have to change our working directory */
			if (chdir("/")) {
				fprintf(stderr,"Unable to bail out to root\n");
				return 1;
			}

			printf("Unmount and remove disk, move files off on another computer,\n");
			printf("re-mount and re-insert and hit ENTER\n");
			waitforenter();

			/* assuming the user has reloaded the disk/flash drive/whatever and remounted
			 * at the same point, jump back into the directory and try to resume our work */
			if (chdir(ppath)) {
				fprintf(stderr,"Unable to reenter capture dir\n");
				return 1;
			}
		}

		sprintf(tmp,CAPTURE_SPRINTF,segmnt);
		printf("Writing ... %s\n",tmp);
		fd = open(tmp,O_WRONLY|O_CREAT|O_TRUNC,0644);
		if (fd < 0) {
			fprintf(stderr,"Unable to open file, %s\n",strerror(errno));
			return 1;
		}
		if ((size_t)write(fd,ROM+segmnt-ROM_offset,ROM_blocksize) != ROM_blocksize) {
			fprintf(stderr,"Unable to write ROM block\n");
			return 1;
		}
		close(fd);
	}

	munmap(ROM,ROM_size);
	close(mem_fd);
	return 0;
}

