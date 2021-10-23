#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

#include "shell.h"

node_t arg_list;
node_t cmd_list;
node_t file_list; 
node_t history;
int    background;
char   MYPS1[100];
char  *MYPATH;
char  *PWD;
char   prompt[10];

void show_prompt()
{
	printf("\n%s", MYPS1);
}

char* env_init(char* env)
{
	char* mypath;
	mypath = getenv(env);
	return mypath;
}

void MYPS1_update()
{
	char tmp[100];
	strncpy(tmp, prompt, 10);
	strcat(tmp, ":");
	strcat(tmp, PWD);
	strcat(tmp, "$ ");
	strncpy(MYPS1, tmp, 100);
	return;
}

int main(int argc, char *argv[])
{
	queue_init(&arg_list);
	queue_init(&cmd_list);
	queue_init(&file_list);
	queue_init(&history);
	MYPATH = env_init("PATH");
	PWD = env_init("PWD");
	strncpy(prompt, "tecii", 10);
	MYPS1_update();
	
	if (signal(SIGCHLD, sig_handler) == SIG_ERR)
		printf("\ncan't catch SIGCHLD\n");

	if (signal(SIGINT, sig_handler) == SIG_ERR)
		printf("it didn't work");
		
	if (signal(SIGTSTP, sig_handler) == SIG_ERR)
		printf("couldn't put process in background\n");

	show_prompt();
        yyparse();
	return 0;
}
