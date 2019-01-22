/*
 * Logger function in C, since Julia 1.0.2 can't handle variadic arguments of
 * different types, like in printf("%s %u", string, unsignedInt)
 *
 * Compile with:
 *     $ gcc -shared -fPIC logger.c -o ../bin/unix64/logger.so
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

typedef enum {
    fmi2OK,
    fmi2Warning,
    fmi2Discard,
    fmi2Error,
    fmi2Fatal,
    fmi2Pending
} fmi2Status;

/*
 * Small helper for logger function
 */
const char* status2string(fmi2Status status)
{
    switch (status) {
        case fmi2OK: return "fmi2OK";
        case fmi2Warning: return "fmi2Warning";
        case fmi2Discard: return "fmi2Discard";
        case fmi2Error: return "fmi2Error";
        case fmi2Fatal: return "fmi2Fatal";
        case fmi2Pending: return "fmi2Pending";
        default: return "unknownState";
    }
}

/*
 * Logger function to give to FMU's as callback
 */
void logger (void* componentEnvironment,
             const char* instanceName,
             fmi2Status status,
             const char* category,
             const char* message, ...)
{
        /* Variables */
        va_list args;
        size_t size;
        char* buffer;

        va_start(args, message);

        size = vsnprintf(NULL, 0, message, args);
        buffer = (char*) calloc(size+1, sizeof(char));

        vsprintf(buffer, message, args);
        printf("Logger: [%s][%s][%s]:\n\t%s\n", instanceName, status2string(status), category, buffer);

        /* Free memory */
        free(buffer);
        va_end(args);
}
