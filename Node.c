#include "Node.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define START_CAPACITY 16

Node_s* initNodeTree(const char* type, const char* value, int32_t lineno)
{
    Node_s* node = NULL;
#ifdef PRINT_PARSER_TREE
    node = (Node_s*) malloc(sizeof(Node_s));
    if (node == NULL)
    {
        fprintf(stderr, "[-] Failed to allocate memory for node.\n");
        exit(1);
    }
    node->lineno = lineno;
    node->type   = type;
    node->value  = value;

    node->children = (Node_s**) malloc(sizeof(Node_s* [START_CAPACITY]));
    if (node->children == NULL)
    {
        fprintf(stderr, "[-] Failed to create tree\n");
        exit(1);
    }
    node->capacity = START_CAPACITY;
    node->size     = 0;
#endif
    return node;
}

void addSubTree(Node_s node[static 1], Node_s* newNode)
{   
#ifdef PRINT_PARSER_TREE
    if (newNode == NULL) return;
    if (node->size == node->capacity)
    {
        node->capacity *= 2;
        void* temp = realloc(node->children, sizeof(Node_s* [node->capacity]));
        if (temp == NULL)
        {
            fprintf(stderr, "[-] Out of memory.\n");
            exit(1);
        }
        node->children = temp;
    }
    node->children[node->size++] = newNode;
#endif
}


void printTree(Node_s node[static 1], int depth)
{
    for (int32_t i = 0; i < depth; ++i)
        printf("  ");
    printf("%s:%s\n", node->type, node->value);
    for (uint32_t i = 0; i < node->size; ++i)
        printTree(node->children[i], depth + 1);
}

static void generateTreeContent(Node_s node[static 1], int count[static 1], FILE file[static 1])
{
    node->id = ++(*count);

    const char* labelFormat = "n%d [label=\"%s:%s\"];\n";
    const char* nnFormat = "n%d -> n%d\n";

    char*   writebuf = NULL;
    int32_t writeSize = snprintf(NULL, 0, labelFormat, node->id, node->type, node->value);
    if (writeSize < 0)
    {
        fprintf(stderr, "[-] Unable to generate tree (sprintf).");
        exit(1);
    }
    writebuf = malloc(sizeof(char[writeSize]));

    sprintf(writebuf, labelFormat, node->id, node->type, node->value);
    fwrite(writebuf, sizeof(*writebuf), writeSize, file);

    for (uint32_t i = 0; i < node->size; ++i)
    {
        generateTreeContent(node->children[i], count, file);

        int32_t oldSize = writeSize;

        writeSize = snprintf(NULL, 0, nnFormat, node->id, node->children[i]->id);
        if (writeSize < 0)
        {
            fprintf(stderr, "[-] Unable to generate tree, recursion\n");
            exit(1);
        }

        if (writeSize > oldSize)
        {
            writebuf = realloc(writebuf, writeSize);
            if (writebuf == NULL)
            {
                fprintf(stderr, "[-] Failed to realloc memory.\n");
                exit(1);
            }
        } 
        memset(writebuf, 0, writeSize);
        sprintf(writebuf, nnFormat, node->id, node->children[i]->id);
        fwrite(writebuf, sizeof(*writebuf), writeSize, file);
    }
    // free(writebuf);
}
void generateTree(Node_s node[static 1])
{
    FILE* file;
    char* fname = "tree.dot";
    file        = fopen(fname, "w");

    int32_t count      = 0;
    char    writebuf[] = "digraph {\n";
    fwrite(writebuf, sizeof(*writebuf), sizeof(writebuf) - 1, file);

    generateTreeContent(node, &count, file);

    fwrite("}", 1, 1, file);
    fclose(file);

    printf("\nBuilt a parse-tree at %s. Use 'make tree' to generate the pdf version.\n", fname);
}
