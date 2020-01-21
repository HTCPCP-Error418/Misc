/*
 * This header file contains the definitions of ANSI color codes that can be
 * used to change the color of text output in C programs
 *
 * USAGE: printf(RED "This text is red." RESET "\n");
 */

#ifndef COLORS_H
#define COLORS_H	//begin COLORS_H


#define RED		"\x1b[31m"
#define GREEN	"\x1b[32m"
#define YELLOW	"\x1b[33m"
#define BLUE	"\x1b[34m"
#define MAGENTA	"\x1b[35m"
#define CYAN	"\x1b[36m"
#define RESET	"\x1b[0m"

#endif	//end COLORS_H
