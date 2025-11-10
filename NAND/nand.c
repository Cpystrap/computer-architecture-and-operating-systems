#include "nand.h"
#include <errno.h>
#include <stdbool.h>
#include <malloc.h>

typedef struct vectorOfNand {
    nand_t** gates;   // array of nand_t gates
    size_t capacity;
    size_t size;
} vector;

struct nand {
    unsigned int e;  // number of entries
    const bool** entriesBool;
    nand_t** entriesNand;
    bool value;  // in a gateway
    ssize_t lengthOfPath;  // LOP at the end of a gateway (= -1 if error)
    bool visited;  // to tell me if value and lengthOfPath is current
    bool visiting;  // needed for dfs
    vector* exits;
};

// For vector

bool vinit(vector* v) {
    nand_t** array = malloc(sizeof (nand_t*) * 4);
    if (!array) {
        return false;
    }
    v->gates = array;
    for (size_t i = 0; i < 4; i++) {
        v->gates[i] = NULL;
    }
    v->capacity = 4;
    v->size = 0;
    return true;
}

size_t vsize(vector* v) {
    return v->size;
}

bool vshrink_to_fit(vector* v) {
    if (v->capacity >= 8 && v->size <= v->capacity / 4) {
        nand_t** temp = realloc(v->gates, (v->capacity / 2) * sizeof (nand_t*));
        if (temp == NULL) {
            return false;
        }
        v->gates = temp;
        v->capacity = v->capacity / 2;
    }
    return true;
}

bool vpush_back(vector* v, nand_t* gate) {
    if (v->size == v->capacity) {
        nand_t** temp = realloc(v->gates, v->capacity * 2 * sizeof (nand_t*));
        if (temp == NULL) {
            return false;
        }
        v->gates = temp;
        v->capacity = v->capacity * 2;
    }

    v->gates[v->size++] = gate;
    return true;
}

bool verase(vector* v, size_t index) {
    //shrinking vector
    bool result = vshrink_to_fit(v);
    if (!result) {   // shrinking failed
        return false;
    }

    for (size_t i = index; i < v->size - 1; i++) {
        v->gates[i] = v->gates[i + 1];
    }
    v->gates[v->size - 1] = NULL;
    v->size--;

    return true;
}

// special functions for reversing changes after fails in memory
// allocation which will work even when realloc will fail

void vreverse_push_back(vector* v, nand_t* gate) {
    v->gates[v->size++] = gate;
    return;
}

void vreverse_erase(vector* v, size_t index) {
    for (size_t i = index; i < v->size - 1; i++) {
        v->gates[i] = v->gates[i + 1];
    }
    v->gates[v->size - 1] = NULL;
    v->size--;
    return;
}

nand_t* vget(vector* v, size_t index) {
    return v->gates[index];
}

// end of vector functions

ssize_t max(ssize_t a, ssize_t b) {
    if (a >= b) {
        return a;
    }
    return b;
}

void dfs(nand_t* gate) {
    if (!gate->visiting) {
        if (gate->e == 0) {   // 0 entries
            gate->lengthOfPath = 0;
            gate->value = false;
            gate->visited = true;
            return;
        }

        gate->visiting = true;
        // +1 to max_lengthOfPath = our LOP
        ssize_t max_lenghtOfPath = 0;
        gate->value = false;
        // I need info about values/LOP from entries
        for (unsigned int i = 0; i < gate->e; ++i) {
            if (!gate->entriesNand[i] && !gate->entriesBool[i]) {  // empty entry
                gate->lengthOfPath = -1;
                gate->visited = true;
                gate->visiting = false;
                return;
            }
            if (gate->entriesNand[i]) {
                if (gate->entriesNand[i]->visited == false) {
                    dfs(gate->entriesNand[i]);  // visit if wasn't visited
                }
                if (gate->entriesNand[i]->lengthOfPath == -1) {  // error
                    gate->lengthOfPath = -1;
                    gate->visited = true;
                    gate->visiting = false;
                    return;
                }
                if (gate->entriesNand[i]->value == false) {
                    gate->value = true;  // one false gives true in NAND
                }
                max_lenghtOfPath = max(max_lenghtOfPath, gate->entriesNand[i]->lengthOfPath);
            }
            else if (gate->entriesBool[i] && *(gate->entriesBool[i]) == false) {
                gate->value = true;  // one false givestrue in NAND
            }
        }
        gate->lengthOfPath = max_lenghtOfPath + 1;
        gate->visiting = false;
        gate->visited = true;
        return;
    }
    else {  // loop
        gate->lengthOfPath = -1;
        gate->visited = true;
        return;
    }
}

void clean_dfs(nand_t* gate) {
    gate->visited = false;
    for (unsigned int i = 0; i < gate->e; ++i) {
        if (gate->entriesNand[i] && gate->entriesNand[i]->visited) {
            clean_dfs(gate->entriesNand[i]);
        }
    }
    return;
}

nand_t* nand_new(unsigned n) {
    nand_t* gateway = (nand_t*)malloc(sizeof (nand_t));
    if (!gateway) {
        errno = ENOMEM;
        return NULL;
    }

    // malloc gates (nand_t) and bool arrays (pointers to them)
    const bool** array1 = (const bool**)malloc(n * sizeof (const bool*));
    if (!array1) {
        errno = ENOMEM;
        free(gateway);
        return NULL;
    }
    nand_t** array2 = (nand_t**)malloc(n * sizeof (nand_t*));
    if (!array2) {
        errno = ENOMEM;
        free(gateway);
        free(array1);
        return NULL;
    }
    for (unsigned int i = 0; i < n; ++i) {
        array1[i] = NULL;
        array2[i] = NULL;
    }

    vector* exits = malloc(sizeof (vector));
    if (!exits) {
        errno = ENOMEM;
        free(gateway);
        free(array1);
        free(array2);
        return NULL;
    }
    if (!vinit(exits)) {
        errno = ENOMEM;
        free(gateway);
        free(array1);
        free(array2);
        free(exits);
        return NULL;
    }

    gateway->entriesBool = array1;
    gateway->entriesNand = array2;
    gateway->e = n;
    gateway->exits = exits;
    gateway->visited = false;
    gateway->visiting = false;

    return gateway;
}

void nand_delete(nand_t *g) {
    if (g) {
        for (unsigned int i = 0; i < g->e; ++i) {
            // change exits of every gateway connected to deleted gateway g
            // (delete g from it)
            if (g->entriesNand[i]) {
                nand_t* entry = g->entriesNand[i];
                size_t j = 0;   // index in a vector of exits
                size_t erase_counter = 0;
                size_t sizeOfExits = vsize(entry->exits);   // to indicate
                // how many times should this while loop go
                size_t howManyTimesLoopWent = 0;
                while (howManyTimesLoopWent < sizeOfExits) {
                    if (vget(entry->exits, j) == g) {
                        // it deletes g from array of exits
                        // erase without shrinking and if after all that
                        // shrinking fails, reverse changes
                        vreverse_erase(entry->exits, j);
                        erase_counter++;
                    } else {
                        j++;
                    }
                    howManyTimesLoopWent++;
                }
                if (!vshrink_to_fit(entry->exits)) {
                    errno = ENOMEM;
                    // reversing changes
                    while (erase_counter > 0) {
                        vreverse_push_back(entry->exits, g);
                        erase_counter--;
                    }
                    return;
                }
            }
        }

        for (size_t i = 0; i < vsize(g->exits); ++i) {
            // change entries of every gateway to which deleted gateway is
            // connected (delete g from it)
            nand_t* exit = vget(g->exits, i);
            for (unsigned int k = 0; k < exit->e; ++k) {
                if (exit->entriesNand[k] && exit->entriesNand[k] == g) {
                    exit->entriesNand[k] = NULL;
                }
            }
        }

        // need to free vector of exits
        free(g->exits->gates);
        free(g->exits);

        // and array of entries
        free(g->entriesNand);
        free(g->entriesBool);

        free(g);
    }
    // if g is NULL then do nothing
}

int nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k) {
    if (g_in && k < g_in->e && g_out) {
        if (!vpush_back(g_out->exits, g_in)) {
            errno = ENOMEM;
            return -1;
        }
        if (g_in->entriesNand[k]) {
            // we should delete g_in from exits vector of unplugged gate
            // (only one time, because unplugged could be connected to other
            // entries of g)
            nand_t* unplugged = g_in->entriesNand[k];
            size_t j = 0;
            while (j < vsize(unplugged->exits) && vget(unplugged->exits, j) != g_in) {
                j++;
            }
            if (j < vsize(unplugged->exits) && vget(unplugged->exits, j) == g_in) {
                if (!verase(unplugged->exits, j)) {
                    errno = ENOMEM;
                    // first erase then change capacity to make sure it will
                    // reverse changes even when realloc fails (by changes I mean
                    // pushing g_in into g_out->exits)
                    vreverse_erase(g_out->exits, g_out->exits->size - 1);
                    vshrink_to_fit(g_out->exits);
                    return -1;
                }
            }
        }
        if (g_in->entriesBool[k]) {
            g_in->entriesBool[k] = NULL;
        }
        g_in->entriesNand[k] = g_out;
        return 0;
    }
    errno = EINVAL;
    return -1;
}

int nand_connect_signal(bool const *s, nand_t *g, unsigned k) {
    if (s && g && k < g->e) {
        if (g->entriesNand[k]) {
            // we should delete g from exits vector of unplugged gate
            // (only one time, because unplugged could be connected to other
            // entries of g)
            nand_t* unplugged = g->entriesNand[k];
            size_t j = 0;
            while (j < vsize(unplugged->exits) && vget(unplugged->exits, j) != g) {
                j++;
            }
            if (j < vsize(unplugged->exits) && vget(unplugged->exits, j) == g) {
                if (!verase(unplugged->exits, j)) {
                    errno = ENOMEM;
                    return -1;
                }
            }
        }
        if (g->entriesNand[k]) {
            g->entriesNand[k] = NULL;
        }
        g->entriesBool[k] = s;
        return 0;
    }
    errno = EINVAL;
    return -1;
}

ssize_t nand_evaluate(nand_t **g, bool *s, size_t m) {
    if (m == 0 || !g || !s) {
        errno = EINVAL;
        return -1;
    }

    for (size_t i = 0; i < m; ++i) {
        if (!g[i]) {
            errno = EINVAL;
            return -1;
        }
    }

    ssize_t max_lengthOfPath = 0;
    bool isError = false;  // to indicate if it was not possible to evaluate
    // (loop or gate without value/signal)
    size_t i = 0;
    while (i < m && !isError) {  // find value and LOP of every given gate
        if (g[i]->visited == false) {
            dfs(g[i]);
        }
        if (g[i]->lengthOfPath == -1) {
            isError = true;
        }
        max_lengthOfPath = max(max_lengthOfPath, g[i]->lengthOfPath);
        i++;
    }

    i = 0;
    while (i < m) {
        if (g[i]->visited) {
            clean_dfs(g[i]);  // reverse changes of dfs
        }
        i++;
    }

    if (isError) {
        errno = ECANCELED;
        return -1;
    } else {
        i = 0;
        while (i < m) {
            s[i] = (bool)g[i]->value;
            i++;
        }
        return max_lengthOfPath;
    }
}

ssize_t nand_fan_out(nand_t const *g) {
    if (!g) {
        errno = EINVAL;
        return -1;
    }
    return (ssize_t)vsize(g->exits);
}

void* nand_input(nand_t const *g, unsigned k) {
    if (!g || k >= g->e) {
        errno = EINVAL;
        return NULL;
    }
    if (!g->entriesNand[k] && !g->entriesBool[k]) {
        errno = 0;
        return NULL;
    }
    if (g->entriesNand[k]) {
        return (void*)g->entriesNand[k];
    }
    return (void*)g->entriesBool[k];
}

nand_t* nand_output(nand_t const *g, ssize_t k) {
    if ( !g || !(k >= 0 && k < (ssize_t)vsize(g->exits)) ) {
        return NULL;
    }
    return vget(g->exits, k);
}
