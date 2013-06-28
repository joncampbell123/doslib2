/* WARNING: This code assumes 16-bit real mode */

#include <sys/types.h>
#include <sys/stat.h>
#include <dos.h>
#include <stdio.h>
#include <fcntl.h>
#include <assert.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include <dos/lib/loader/dso16.h>

struct ne_module*			ne_mod_first = NULL;
unsigned char				ne_mod_ne_debug = 0;
unsigned char				ne_mod_debug = 0;
struct ne_module*			(*ne_module_default_lookup)(struct ne_module *to_mod,const char *modname) = ne_module_default_lookup_default;
char**					ne_module_dso_file_extensions = ne_module_dso_file_extensions_default;
char**					ne_module_dso_search_paths = ne_module_dso_search_paths_default;

static unsigned char ne_module_inited = 0;
static int ne_module_dso_search_paths_default_write = 1;
char *ne_module_dso_search_paths_default[] = {
	"",			/* current directory */
	NULL,			/* extra NULL slot to fill in from environment block */
	NULL
};

char *ne_module_dso_file_extensions_default[] = {
	".DSO",
	NULL
};

void ne_module_free_all() {
	ne_module_gclibrary();
	while (ne_mod_first != NULL) {
		if (ne_mod_debug) fprintf(stdout,"ne mod: freeing %Fp\n",(void far*)(ne_mod_first));
		ne_module_free(ne_mod_first);
		ne_mod_first = ne_mod_first->next;
	}
}

void ne_module_init() {
	if (!ne_module_inited) {
		char *x;
		
		x = getenv("DSO_LIBRARY_PATH");
		if (x != NULL) ne_module_dso_search_paths_default[ne_module_dso_search_paths_default_write++] = x;

		ne_module_inited = 1;
	}
}

/* "name" can be either the resident name (such as "EXAMDLL1") or the file name ("examdll1.dso"),
 * or, the full path if a full path is given ("C:\DOS\EXAMDLL1.DSO") */
struct ne_module *ne_module_getmodulehandle(const char *name) {
	struct ne_module *ne = ne_mod_first;
	size_t namelen = strlen(name);

	if (namelen == 0) return NULL;
	while (ne != NULL) {
		/* match by "resident name" entry #0 which contains the module name (well, minus the extension) */
		if (ne->ne_resident_names != NULL) {
			unsigned char *p = ne->ne_resident_names;
			unsigned char *f = p + ne->ne_resident_names_length;
			unsigned char len = *p++;
			if ((p+len) <= f) {
				if ((size_t)len == namelen) {
					if (strncasecmp(name,p,len) == 0) return ne;
				}
				else {
					/* Hm, are we trying to match name == "EXAMDLL2.DSO" to "EXAMDLL2"? */
					if (namelen >= 4 && name[namelen-4] == '.' && (size_t)len == (namelen-4)) {
						if (strncasecmp(name,p,len-4) == 0) return ne;
					}
				}
			}
		}

		ne = ne->next;
	}

	return NULL;
}

struct ne_module* ne_module_default_lookup_default(struct ne_module *to_mod,const char *modname) {
	return ne_module_loadlibrary_nref(modname);
}

struct ne_module *ne_module_loadlibrary(const char *name) {
	struct ne_module *ne = ne_module_loadlibrary_nref(name);
	if (ne == NULL) return NULL;
	ne_module_addref(ne);
	return ne;
}

struct ne_module *ne_module_loadlibrary_nref(const char *name) {
	struct ne_module *ne,*nx,new_ne;
	struct stat st;
	size_t srchi;
	size_t namel;
	size_t extl;
	size_t exti;
	char *tmp;
	char *ext;

	ne = ne_module_getmodulehandle(name);
	if (ne != NULL) return ne;
	if (ne_module_dso_search_paths == NULL) return NULL;
	namel = strlen(name);

	/* then we have to locate it */
	ne_module_zero(&new_ne);
	new_ne.import_module_lookup = ne_module_default_lookup;
	new_ne.enable_debug = ne_mod_ne_debug;
	ext = strrchr(name,'.');
	extl = (ext != NULL) ? strlen(ext) : 0;

	/* scan for the file, using search paths and extensions */
	for (srchi=0;new_ne.ne_sega == NULL && ne_module_dso_search_paths[srchi] != NULL;srchi++) {
		unsigned int l = strlen(ne_module_dso_search_paths[srchi]);

		if (new_ne.ne_sega == NULL && ext != NULL) {
			tmp = malloc(l+namel+2); /* search path + \ + name + NUL */
			if (tmp == NULL) continue;

			if (l != 0) sprintf(tmp,"%s\\",ne_module_dso_search_paths[srchi]);
			else tmp[0] = 0;
			strcat(tmp,name);
			if (ne_mod_debug) fprintf(stdout,"Searching for '%s': trying %s\n",name,tmp);
			if (stat(tmp,&st) == 0 && S_ISREG(st.st_mode))
				ne_module_general_load(&new_ne,tmp);

			free(tmp);
		}
		if (new_ne.ne_sega == NULL && ext == NULL && ne_module_dso_file_extensions != NULL) {
			for (exti=0;new_ne.ne_sega == NULL && ne_module_dso_file_extensions[exti] != NULL;exti++) {
				unsigned int el = strlen(ne_module_dso_file_extensions[exti]);

				tmp = malloc(l+namel+el+2); /* search path + \ + name + ext + NUL */
				if (tmp == NULL) continue;

				if (l != 0) sprintf(tmp,"%s\\",ne_module_dso_search_paths[srchi]);
				else tmp[0] = 0;
				strcat(tmp,name);
				if (ext == NULL) strcat(tmp,ne_module_dso_file_extensions[exti]);
				if (ne_mod_debug) fprintf(stdout,"Searching for '%s': trying %s\n",name,tmp);
				if (stat(tmp,&st) == 0 && S_ISREG(st.st_mode))
					ne_module_general_load(&new_ne,tmp);

				free(tmp);
			}
		}
	}

	if (new_ne.ne_sega != NULL) {
		ne = (struct ne_module*)malloc(sizeof(struct ne_module));
		if (ne == NULL) {
			if (ne_mod_debug) fprintf(stdout,"Unable to alloc NE link for %s\n",name);
			ne_module_free(&new_ne);
			return NULL;
		}
		memcpy(ne,&new_ne,sizeof(new_ne));
		if (ne_mod_debug) fprintf(stdout,"Successfully loaded %Fp, %s\n",(void far*)ne,name);
	}

	/* if the load succeeded, add it to the linked list */
	if (ne != NULL) {
		if (ne_mod_first == NULL) {
			ne_mod_first = ne;
		}
		else {
			nx = ne_mod_first;
			while (nx->next != NULL) nx = nx->next;
			nx->next = ne;
			ne->prev = nx;
		}
	}

	return ne;
}

void ne_module_freelibrary(struct ne_module *n) {
	ne_module_release(n);
}

void ne_module_gclibrary() {
	struct ne_module *n = ne_mod_first,*nex;
	int again=0;

	while (n) {
		if (n->reference_count == 0) {
			if (ne_mod_debug) fprintf(stdout,"ne mod: %Fp refcount == 0, garbage-collecting now\n",(void far*)n);
			ne_module_free(n);
			if (n->prev == NULL) {
				assert(n == ne_mod_first);
				ne_mod_first = n->next;
				ne_mod_first->prev = NULL;
				nex = ne_mod_first;
			}
			else {
				nex = n->next;
				n->prev->next = n->next;
				if (n->next != NULL) n->next->prev = n->prev;
			}
			again = 1;
			free(n);
			n = nex;
		}
		else {
			n = n->next;
		}

		if (n == NULL && again) {
			again = 0;
			n = ne_mod_first;
		}
	}
}

