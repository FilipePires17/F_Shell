#ifndef SHELL_H
#define SHELL_H

#include "queue.h"

int yylex();
int yyerror(char *);

#define MAX_ARGS 50		// Maximum number of arguments
#define MAX_NAME 128		// Maximum length of an identifier

#define INSERT_IFILE(x)		\
{				\
	FILE_LIST *tmp;		\
	tmp = insert_file(x);	\
	tmp->ifile = 1;		\
}

#define INSERT_OFILE(x, y)	\
{				\
	FILE_LIST *tmp;		\
	tmp = insert_file(x);	\
	tmp->ofile  = 1;	\
	tmp->append = y;	\
}

#define INSERT_EFILE(x, y)	\
{				\
	FILE_LIST *tmp;		\
	tmp = insert_file(x);	\
	tmp->efile  = 1;	\
	tmp->append = y;	\
}

/* List of file names used for redirections */
typedef struct {
	node_t		node;
	char		name[MAX_NAME];	// File name
	unsigned int	ifile  : 1;	// if 1, an input redirection was present < file_name
	unsigned int	ofile  : 1;	// if 1, an output redirection was present > file_name
	unsigned int	efile  : 1;	// if 1, an error redirection was present 2> file_name
	unsigned int	append : 1;	// if 1, indicates an append redirection >> file_name
} FILE_LIST;

/* List of arguments for a command */
typedef struct _a {
	node_t	node;
	char	arg[MAX_NAME];
} ARG_LIST;

/* Lists of commands separated by a pipe (|) */
typedef struct {
	node_t	node;
	node_t	args;		// List of arguments for the command (cmd)
	node_t	files;		// List of input/output/error redirections
	char	cmd[MAX_NAME];	// Command (first word in the command line)
} CMD_LIST;

typedef struct {
	node_t  node;
	char    line[MAX_NAME*MAX_ARGS];
} HISTORY_LIST;

/* Global variables that the parser uses to build a list of commands.	*/ 
extern node_t arg_list;
extern node_t cmd_list;
extern node_t file_list;
extern node_t history;

extern int    background;	// if 1, the command line has the background operator &
extern char   MYPS1[100];
extern char   prompt[10];

extern char  *MYPATH;
extern char  *PWD;

/* Functions that I use in the parser.		*/
int execute(); 
void insert_arg_list(char *cmd);
void free_cmd_list();
void create_cmd(char *cmd);
void show_prompt();
void MYPS1_update();
FILE_LIST *insert_file(char *file);

void sig_handler(int signo);
int yyparse();
#endif	/* SHELL_H */
