#include "tree_sitter/alloc.h"
#include <stdlib.h>

#ifdef TREE_SITTER_REUSE_ALLOCATOR
void *(*ts_current_malloc)(size_t)        = malloc;
void *(*ts_current_calloc)(size_t,size_t) = calloc;
void *(*ts_current_realloc)(void*,size_t) = realloc;
void  (*ts_current_free)(void*)           = free;
#endif
