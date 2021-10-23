%{
#include <string.h>
#include <y.tab.h>
%}

%%
\n { return NEWLINE; }

[ \t] { }

">" {return GREAT; }
"<" {return LESS; }
">>" {return GREATGREAT; }
"2>" {return GREATERROR; }
"|" {return PIPE;}
"&" {return AMPERSAND; }


\"(\\.|[^"\\])*\" {
yylval.string_val = strdup(yytext);
return WORD;
} 

\'(\\.|[^'\\])*\' {
yylval.string_val = strdup(yytext);
return WORD;
} 

[A-Za-z0-9/_=:~$%\-\.][A-Za-z0-9/_=:~$%\-\.]* { /* characteres accepted in identifiers */
yylval.string_val = strdup(yytext);
return WORD;
}

. {
return NOTOKEN;
}

%%

