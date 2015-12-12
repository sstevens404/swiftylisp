//
//  main.c
//  Lisp
// 
//  Created by Stanford Stevens on 10/14/15.
//  Copyright (c) 2015 Stanford Stevens. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>

#define MAX_ATOM_LENGTH 100

struct Node;

struct Atom {
    char text[MAX_ATOM_LENGTH];
};

struct List {
    int count;
    struct Node *items;
};

enum NodeType {
    Atom,
    List
};

struct Node {
    enum NodeType type;
    union {
        struct Atom atom;
        struct List list;
    };
};

// forward declare
struct Node parseNode(FILE *fp);
void printList(struct List *list); 
int evaluateNode(struct Node *node);
int evaluateList(struct List *list);

int fpeekc(FILE *fp) {
    int c = fgetc(fp);
    fseek(fp,-1,SEEK_CUR);
    return c;
}

void fexpect(FILE *fp, char expect) {
    int c = fgetc(fp);
    if (c != expect) {
        printf("error, expected '%c', got '%c'\nexiting.", expect, c);
        exit(0);
    }
}

struct Atom parseAtom(FILE *fp) {
    int count = 0;
    struct Atom atom = {0};

    while (1) {
        int c = fpeekc(fp);

        if (c == ' ' || c == ')' || c == EOF) {
            break;
        }

        if (count >= MAX_ATOM_LENGTH) {
            printf("atom longer than %i. \n exiting.", MAX_ATOM_LENGTH);
            exit(0);
        }

        atom.text[count++] = c;

        fgetc(fp); // consume the peeked char
    }
    
    atom.text[count] = 0;
    
    return atom;
}

struct List parseList(FILE *fp) {
    struct List list = {0};
    fexpect(fp,'(');

    while (1) {
        if (!list.items) {
            list.items = malloc(sizeof(struct Node));
        } else {
            list.items = realloc(list.items,sizeof(struct Node) * (list.count+1));
        }

        list.items[list.count] = parseNode(fp);
        list.count++;

        int c = fgetc(fp);
        if (c == ')' || c == EOF) {
            break;
        }
    }
    return list;
}

struct Node parseNode(FILE *fp) {
    struct Node node = {0};
    if (fpeekc(fp) == '(') {
        node.type = List;
        node.list = parseList(fp);
    } else {
        node.type = Atom;
        node.atom = parseAtom(fp);
    }
    return node;
}

void printNode(struct Node *n) {
    if (n->type == Atom) {
        printf("%s\n", n->atom.text);
    } else {
        printList(&((*n).list));
    }
}

void printList(struct List *list) {
    printf("(\n");

    for (int i=0; i < (*list).count; i++) {
        struct Node *a = &(list->items[i]);
        printNode(a);
    }

    printf(")\n");
}

int atomValue(struct Atom *atom) {
    return atoi(atom->text);
}

int evaluatePlus(struct List *list) {
    if (list->count == 0) {
        return 0;
    } 

    int accumulator = 0;

    for (int i = 1; i < list->count; ++i) {
        accumulator += evaluateNode(&(list->items[i]));
    }

    return accumulator;
}

int evaluateMultiplication(struct List *list) {
        if (list->count == 0) {
        return 0;
    } 

    int accumulator = 1;

    for (int i = 1; i < list->count; ++i) {
        accumulator *= evaluateNode(&(list->items[i]));
    }

    return accumulator;
}

int evaluateList(struct List *list) {
    if (list->count < 2) {
        return 0;
    }

    struct Node operator = list->items[0];

    if (operator.type != Atom) { // TODO: handle list as first element
        return 0;
    }

    char operatorText = operator.atom.text[0];

    if (operatorText == '+') {
        return evaluatePlus(list);
    } else if (operatorText == '*') {
        return evaluateMultiplication(list);
    }

    return 0;
}

int evaluateNode(struct Node *node) {
    switch (node->type) {
        case Atom: return atomValue(&node->atom);    
        case List: return evaluateList(&node->list);
    }
}

int main(int argc, const char * argv[]) {
    FILE *fp = fopen("sample.lisp", "r");
    
    if (!fp) {
        printf("couldn't open file");
        return -1;
    }

    struct Node rootNode = parseNode(fp);
//     printNode(&rootNode);

    int result = evaluateNode(&rootNode);
    printf("result: %i\n",result);

    fclose(fp);
    
    return 0;
}





