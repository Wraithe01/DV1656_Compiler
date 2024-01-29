#include <stdio.h>

#include "parser.tab.h"
#include "settings.h"
#include "Node.h"

extern FILE* yyin;

extern Node_s* root;


int main(int argc, char** argv)
{
    // Reads from file if a file name is passed as an argument. Otherwise, reads from stdin.
    if (argc > 1)
    {
        if (!(yyin = fopen(argv[1], "r")))
        {
            perror(argv[1]);
            return 1;
        }
    }
    yyparse();
    generateTree(root);
    fclose(yyin);
    return 0;
}
