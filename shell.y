%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include "shell.h"	
%}

%start command_list;

%union { char *string_val; }

%token NOTOKEN GREAT NEWLINE <string_val>WORD GREATGREAT PIPE AMPERSAND LESS GREATERROR

%%

arg_list: arg_list WORD { insert_arg_list($2);  }
	| 
	;

cmd_and_args: WORD arg_list io_modifier_list { create_cmd($1); }
	;

pipe_list: pipe_list PIPE cmd_and_args {}
	| cmd_and_args 
	;

io_modifier: GREATGREAT WORD {INSERT_OFILE($2, 1);}
	| GREAT WORD         {INSERT_OFILE($2, 0);}
	| GREATERROR WORD    {INSERT_EFILE($2, 0);}
	| LESS WORD	     {INSERT_IFILE($2);}
	;

io_modifier_list: io_modifier_list io_modifier
	| /* empty */ //{queue_init(&file_list);}
	;

background_optional: AMPERSAND {background = 1; }
	| /* empty */ {background = 0;}
	;

command_line: pipe_list background_optional NEWLINE
	| NEWLINE 
	| error NEWLINE {yyerrok; free_cmd_list();}
	;

command_list: command_list command_line {execute();}
	| 
	;

%%
extern int errno;

void sig_handler(int signo)
{	
	if (signo == SIGCHLD) {
		int pid;
		pid = wait(NULL);
	}
	if (signo == SIGINT) {
		printf("\n");
		show_prompt();
	}
	if (signo == SIGTSTP) {
		free_cmd_list();	
	}
}


int yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
	return 1;
}

int yywrap()
{
	return 1;
}


void *my_malloc(int size)
{
	void *tmp = malloc(size);
	if (tmp == NULL) {
		fprintf(stderr, "Could not alloc memory\n");
		exit(1);
	}
	memset(tmp, 0, size);
	return tmp;
}

void free_arg_list(node_t *head)
{
	ARG_LIST *arg_list_tmp;

	while (!is_empty(head)) {
		arg_list_tmp = (ARG_LIST*)dequeue((node_t*)head);
		free(arg_list_tmp);
	}
}

void free_file_list(node_t *head)
{
	FILE_LIST *file_list_tmp;
	
	while (!is_empty(head)) {
		file_list_tmp = (FILE_LIST*)dequeue((node_t*)head);
		free(file_list_tmp);
	}
}

void free_cmd_list()
{
	CMD_LIST *cmd_list_tmp;
	
	while (!is_empty(&cmd_list)) {
		cmd_list_tmp = (CMD_LIST*)dequeue((node_t*)&cmd_list);
		free_arg_list(&cmd_list_tmp->args);
		free_file_list(&cmd_list_tmp->files);
		free(cmd_list_tmp);
	}
	queue_init(&arg_list);
	queue_init(&file_list);
}

void show_arg_list(node_t *head)
{
	node_t *tmp = head->next;
	do {
		ARG_LIST *a = (ARG_LIST*)tmp;
		printf(" %s", a->arg);
		tmp = tmp->next;
	} while (tmp != head);
}

void show_file_list(node_t *head)
{
	node_t *tmp = head->next;
	do {
		FILE_LIST *f = (FILE_LIST *)tmp;
		if (f->ifile)
			printf(" < %s", f->name);
		else if (f->ofile)
			printf(" %s %s", f->append ? ">>" : ">", f->name); //
		else if (f->efile)
			printf(" %s %s", f->append ? "2>>" : "2>", f->name); // 
		tmp = tmp->next;
	} while (tmp != head);
}

void show_cmd_list(node_t *head)
{
	node_t *tmp = head->next;
	do {
		CMD_LIST *cmd = (CMD_LIST *)tmp;
		printf("%s", cmd->cmd);
		if (!is_empty(&cmd->args)) {
			show_arg_list(&cmd->args);
		}
		if (!is_empty(&cmd->files)) {
			show_file_list(&cmd->files);
		}
		tmp = tmp->next;
		printf(" ");
	} while (tmp != head);
}

void insert_arg_list(char *arg)
{
	ARG_LIST *tmp;
	
	tmp = my_malloc(sizeof(ARG_LIST)); 
	strncpy(tmp->arg, arg, MAX_NAME);
	enqueue((node_t*)&arg_list, (node_t*)tmp);
}

void replace_head(node_t *prev, node_t *new)
{
	prev->prev->next = new;
	prev->next->prev = new;
	new->prev = prev->prev;
	new->next = prev->next;
}

void create_cmd(char *cmd)
{
	CMD_LIST *tmp;
	
	tmp = my_malloc(sizeof(CMD_LIST));
	strncpy(tmp->cmd, cmd, MAX_NAME);
	if (is_empty(&arg_list))
		queue_init(&tmp->args);
	else 
		replace_head(&arg_list, &tmp->args);
	if (is_empty(&file_list))
		queue_init(&tmp->files);
	else
		replace_head(&file_list, &tmp->files);
	enqueue(&cmd_list, (node_t*)tmp);
	queue_init(&arg_list);
	queue_init(&file_list);
}

FILE_LIST *insert_file(char *file)
{
	FILE_LIST *tmp;
	
	tmp = my_malloc(sizeof(FILE_LIST));
	strncpy(tmp->name, file, MAX_NAME);
	enqueue(&file_list, (node_t*)tmp);
	return tmp;
}

void build_args(char **argv, node_t *head)
{
	int i = 1;
	node_t *tmp = head->next;
	
	do {
		ARG_LIST *arg = (ARG_LIST*)tmp;
		argv[i++] = arg->arg;
		tmp = tmp->next;
	} while (tmp != head);
}

char **build_argv(CMD_LIST *cmd)
{
	char **argv;
	int i = 0;

	argv = my_malloc(sizeof(char *) * MAX_ARGS);
	argv[i++] = cmd->cmd;
	if (!is_empty(&cmd->args))
		build_args(argv, &cmd->args);
	return argv;
}


int list_elem_counter(node_t* head)
{
	int counter = 0;
	node_t * tmp = head->next;
	while(tmp != head) {
		counter++;
		tmp = tmp->next;
	}
	return counter;
}

void exit_cmd()
{
	printf("\n");
	exit(0);
}

void export_cmd()
{
	node_t *tmp = (&cmd_list)->next;
	CMD_LIST* cmd = (CMD_LIST*)tmp;
	node_t* args = &cmd->args;
	tmp = args->next;
	ARG_LIST* argsx = (ARG_LIST*)tmp;
	char * arg = argsx->arg;
	if (is_empty(args)) {
		printf("expected argument to 'export'");
		return;
	}
	if (!strncmp(arg, "/", 1)) {
		strcat(MYPATH, ":");
		strcat(MYPATH, arg);
		return;
	}
	else {
		printf("A program path must begin with '/'\n");
		return;
	}
}

void cd_cmd()
{
	node_t *tmp = (&cmd_list)->next;
	CMD_LIST* cmd = (CMD_LIST*)tmp;
	node_t* args = &cmd->args;
	tmp = args->next;
	ARG_LIST* argsx = (ARG_LIST*)tmp;
	char * arg = argsx->arg;
	if (is_empty(args)) {
		printf("expected argument to 'cd'\n");
		return;
	}
	if (chdir(arg) != 0) {
		perror("chdir");
	}
	else {
		strncpy(PWD, arg, 89);
		MYPS1_update();
	}
	return;
}

char *cmd_line()
{
	char  *full_line;
	full_line = my_malloc(MAX_NAME*MAX_ARGS);
	node_t *tmp_cmd = (&cmd_list)->next;
	do {
		CMD_LIST *cmd = (CMD_LIST *)tmp_cmd;
		strcat(full_line, cmd->cmd);
		if (!is_empty(&cmd->args)) {
			node_t *tmp_args = (&cmd->args)->next;
			do {
				ARG_LIST *a = (ARG_LIST*)tmp_args;
				strcat(full_line, " ");
				strcat(full_line, a->arg);
				tmp_args = tmp_args->next;
			} while (tmp_args != &cmd->args);
		}
		if (!is_empty(&cmd->files)) {
			node_t *tmp_files = (&cmd->files)->next;
			do {
				FILE_LIST *f = (FILE_LIST *)tmp_files;
				if (f->ifile) {
					strcat(full_line, " < ");
					strcat(full_line, f->name);
				}
				else if (f->ofile) {
					strcat(full_line, f->append ? " >> " : " > ");
					strcat(full_line, f->name);
				}
				else if (f->efile) {
					strcat(full_line, f->append ? " 2>> " : " 2> ");
					strcat(full_line, f->name);
				}
				tmp_files = tmp_files->next;
			} while (tmp_files != &cmd->files);
		}
		if (tmp_cmd->next != &cmd_list) {
			strcat(full_line, " | ");
		}
		tmp_cmd = tmp_cmd->next;
	} while (tmp_cmd != &cmd_list);
	return full_line;
}

void history_update()
{
	char * line;
	HISTORY_LIST *history_entry;
	history_entry = my_malloc(sizeof(HISTORY_LIST));
	line = cmd_line();
	strcpy(history_entry->line, line);
	enqueue(&history, (node_t *)history_entry);
	if (list_elem_counter(&history)>50) {
		HISTORY_LIST *tmp;
		tmp = (HISTORY_LIST *)dequeue((node_t *)&history);
		free(tmp);
	}
	return;
}

void history_cmd()
{
	node_t *tmp_history;
	tmp_history = (&history)->next;
	while (tmp_history != &history) {
		HISTORY_LIST *line = (HISTORY_LIST *)tmp_history;
		printf("%s\n", line->line);
		tmp_history = tmp_history->next;
	}
	return;
}

void chppt_cmd()
{
	node_t *tmp = (&cmd_list)->next;
	CMD_LIST* cmd = (CMD_LIST*)tmp;
	node_t* args = &cmd->args;
	tmp = args->next;
	ARG_LIST* argsx = (ARG_LIST*)tmp;
	char * arg = argsx->arg;
	if (is_empty(args)) {
		printf("expected argument to 'chppt'\n");
		return;
	}
	strncpy(prompt, arg, 10);
	MYPS1_update();
	return;
}


typedef struct {
	char cmd[MAX_NAME];
	void (*f)();
} SHELL_CMD;

SHELL_CMD shell_cmds[] = {
	{"exit", 	exit_cmd},
	{"export", 	export_cmd},
	{"cd", 		cd_cmd},
	{"history", history_cmd},
	{"chppt", 	chppt_cmd}
};

int num_shell_cmds = 5;

/*
  This function is called when the user press ENTER after a command line.
  The global variable has a command list. A command list are all the commands
  separated by a pipe (|).
  Ex: cat < input.txt | sort -n -r > output.txt
  Produces a list with two commands:
  1. cat 
  2. sort -n -r
  and a list of IO modifiers for each command
  1. < input.txt
  2. > output.txt
 */

int execute()
{
	if (!is_empty(&cmd_list)) {
		show_cmd_list(&cmd_list);
		printf("\nbackground: %d\n", background);
		printf("%d\n", list_elem_counter(&cmd_list));
	}
	else {
		show_prompt();
		return 0;
	}

	int pid;
	node_t *tmp;
	int num_cmds;
	int tmpin  = dup(0); // entrada padrão
	int tmpout = dup(1); // saída padrão
	int tmperr = dup(2); // saída de erro padrão
	int fdin;
	int fdout;
	int fderr;
	CMD_LIST *cmd;

	FILE_LIST *i_file, *o_file, *e_file;

	i_file = o_file = e_file = my_malloc(sizeof(FILE_LIST));

	num_cmds = list_elem_counter(&cmd_list);

	tmp = (&cmd_list)->next;
	while(tmp != &cmd_list) {
		cmd = (CMD_LIST *)tmp;
		node_t *tmp2 = (&cmd->files)->next;
		while(tmp2 != &cmd->files) {
			FILE_LIST* aux = (FILE_LIST*)tmp2;
			if (aux->ifile) {
				i_file = aux;
			}
			else if (aux->ofile) {
				o_file = aux;
			}
			else if (aux->efile) {
				e_file = aux;
			}
			tmp2 = tmp2->next;
		}
		tmp = tmp->next;
	}
	
	if (i_file->ifile) {
		fdin = open(i_file->name, O_RDONLY);
		if (fdin < 0) {
			printf("Error: %d", errno);
			perror("Program");
		}
	}
	else
		fdin = dup(tmpin);



	history_update();

	tmp = (&cmd_list)->next;
	int i = 0;
	while (tmp != &cmd_list) {
		_Bool shell_cmd_executed = 0;
		dup2(fdin, 0);
		close(fdin);

		int fdpipe[2];
		if (pipe(fdpipe) < 0) {
			perror("pipe");
			exit(1);
		}

		cmd = (CMD_LIST *)tmp;

		for (int j = 0; j < num_shell_cmds; j++) {
			if (!strcmp(cmd->cmd, shell_cmds[j].cmd)) {
				(shell_cmds[j].f)();
				shell_cmd_executed = 1;
			}
		}
		
		if (shell_cmd_executed)
			break;

		if (i == num_cmds-1) {
			if (o_file->ofile) {
				if (o_file->append) {
					fdout = open(o_file->name, O_APPEND);
				}
				else {
					fdout = open(o_file->name, O_WRONLY | O_TRUNC | O_CREAT, S_IWUSR | S_IRUSR);
				}
			}
			else if (e_file->efile) {
				if (e_file->append) {
					fderr = open(e_file->name, O_APPEND | O_CREAT, S_IWUSR | S_IRUSR);
				}
				else {
					fderr = open(e_file->name, O_WRONLY | O_TRUNC | O_CREAT, S_IWUSR | S_IRUSR);
				}
			}
			else {
				fdout = dup(tmpout);
				fderr = dup(tmperr);
			}
			close(fdpipe[0]);
			close(fdpipe[1]);
		}
		else {
			fdout = fdpipe[1];
			fdin  = fdpipe[0];
		}

		dup2(fdout, 1);
		dup2(fderr, 2);
		close(fdout);
		close(fderr);

		pid = fork();
		if (pid < 0)
			perror("fork:");
		else if (pid == 0) {
			char **argv;
			
			argv = build_argv(cmd);
			char pathenv[strlen(MYPATH) + sizeof("PATH=")];
			sprintf(pathenv, "PATH=%s", MYPATH);
			char *envpath[] = {pathenv, NULL};
			if(execvpe(argv[0], argv, envpath) < 0) {
				perror("execp:");
				exit(1);
			}
		}
		tmp = tmp->next;
		i++;
	}

	dup2(tmpin,  0);
	dup2(tmpout, 1);
	dup2(tmperr, 2);
	close(tmpin);
	close(tmpout);
	close(tmperr);

	if(!background) {
		int status;
		if (signal(SIGTSTP, sig_handler) == SIG_ERR)
			printf("couldn't put process in background\n");
		else {
			kill(pid, SIGTSTP);
		}
		waitpid(pid, &status, 0);
	}
	else {
		printf("pid [%d]", pid);
	}

	free_cmd_list();
	show_prompt();
	return 0;
}

