#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <getopt.h>
#include <errno.h>
#include <math.h>

#define BASE64_CHARS "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
#define BASE91_CHARS "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""
#define BASE85_CHARS  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~"
#define BASE122_CHARS "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r\x0b\x0c"

typedef enum {
    BASE64,
    BASE85,
    BASE91,
    BASE122
} base_type_t;

typedef struct {
    int binary;
    int decode;
    int ignore_garbage;
    int wrap_cols;
    base_type_t base_type;
    char **files;
    int file_count;
} options_t;

/* Base91 encoding/decoding functions */
static void encode_base91(FILE *input, FILE *output, int wrap_cols) {
    unsigned char buf[2];
    unsigned int val = 0;
    int bits = 0;
    int cols = 0;

    while (!feof(input)) {
        int n = fread(buf, 1, 2, input);
        if (n == 0) break;

        if (n == 1) {
            val = (val << 8) | buf[0];
            bits += 8;
        } else {
            val = (val << 16) | (buf[0] << 8) | buf[1];
            bits += 16;
        }

        while (bits >= 13) {
            bits -= 13;
            int idx = (val >> bits) & 0x1FFF;
            int hi = idx / 91;
            int lo = idx % 91;

            fputc(BASE91_CHARS[hi], output);
            fputc(BASE91_CHARS[lo], output);

            cols += 2;
            if (wrap_cols > 0 && cols >= wrap_cols) {
                fputc('\n', output);
                cols = 0;
            }
        }
    }

    if (bits > 0) {
        int idx = (val << (13 - bits)) & 0x1FFF;
        int hi = idx / 91;
        int lo = idx % 91;

        fputc(BASE91_CHARS[hi], output);
        fputc(BASE91_CHARS[lo], output);
    }

    if (wrap_cols > 0 && cols > 0) {
        fputc('\n', output);
    }
}

static void decode_base91(FILE *input, FILE *output, int ignore_garbage) {
    int val = 0;
    int bits = 0;
    int ch;

    while ((ch = fgetc(input)) != EOF) {
        if (ignore_garbage && !strchr(BASE91_CHARS, ch)) {
            continue;
        }

        const char *pos = strchr(BASE91_CHARS, ch);
        if (!pos) {
            fprintf(stderr, "Invalid character: %c\n", ch);
            exit(1);
        }

        val = (val * 91) + (pos - BASE91_CHARS);
        bits += 13;

        while (bits >= 8) {
            bits -= 8;
            fputc((val >> bits) & 0xFF, output);
        }
    }
}

/* Base64 encoding */
static void encode_base64(FILE *input, FILE *output, int wrap_cols) {
    unsigned char buf[3];
    int cols = 0;

    while (!feof(input)) {
        int n = fread(buf, 1, 3, input);
        if (n == 0) break;

        unsigned int val = (buf[0] << 16) | ((n > 1 ? buf[1] : 0) << 8) | (n > 2 ? buf[2] : 0);

        fputc(BASE64_CHARS[(val >> 18) & 0x3F], output);
        fputc(BASE64_CHARS[(val >> 12) & 0x3F], output);
        cols += 2;

        if (n > 1) {
            fputc(BASE64_CHARS[(val >> 6) & 0x3F], output);
            cols++;
        } else {
            fputc('=', output);
            cols++;
        }

        if (n > 2) {
            fputc(BASE64_CHARS[val & 0x3F], output);
            cols++;
        } else {
            fputc('=', output);
            cols++;
        }

        if (wrap_cols > 0 && cols >= wrap_cols) {
            fputc('\n', output);
            cols = 0;
        }
    }

    if (wrap_cols > 0 && cols > 0) {
        fputc('\n', output);
    }
}

static void decode_base64(FILE *input, FILE *output, int ignore_garbage) {
    int val = 0;
    int bits = 0;
    int ch;

    while ((ch = fgetc(input)) != EOF) {
        if (ch == '=') break;
        if (ignore_garbage && !strchr(BASE64_CHARS, ch) && !isspace(ch)) {
            continue;
        }

        const char *pos = strchr(BASE64_CHARS, ch);
        if (!pos) {
            if (!ignore_garbage) {
                fprintf(stderr, "Invalid character: %c\n", ch);
                exit(1);
            }
            continue;
        }

        val = (val << 6) | (pos - BASE64_CHARS);
        bits += 6;

        if (bits >= 8) {
            bits -= 8;
            fputc((val >> bits) & 0xFF, output);
        }
    }
}

/* Base85 encoding */
static void encode_base85(FILE *input, FILE *output, int wrap_cols) {
    unsigned char buf[4];
    int cols = 0;

    while (!feof(input)) {
        int n = fread(buf, 1, 4, input);
        if (n == 0) break;

        unsigned int val = (buf[0] << 24) | ((n > 1 ? buf[1] : 0) << 16) |
                          ((n > 2 ? buf[2] : 0) << 8) | (n > 3 ? buf[3] : 0);

        if (val == 0 && n == 4) {
            fputc('z', output);
            cols++;
        } else {
            for (int i = 4; i >= 0; i--) {
                if (i < n || i == 4) {
                    int idx = (val / (unsigned int)pow(85, i)) % 85;
                    fputc(BASE85_CHARS[idx], output);
                    cols++;
                }
            }
        }

        if (wrap_cols > 0 && cols >= wrap_cols) {
            fputc('\n', output);
            cols = 0;
        }
    }

    if (wrap_cols > 0 && cols > 0) {
        fputc('\n', output);
    }
}

static void decode_base85(FILE *input, FILE *output, int ignore_garbage) {
    unsigned int val = 0;
    int count = 0;
    int ch;

    while ((ch = fgetc(input)) != EOF) {
        if (ignore_garbage && !strchr(BASE85_CHARS, ch) && ch != 'z') {
            continue;
        }

        if (ch == 'z') {
            // Special case for 'z' (represents four null bytes)
            fputc(0, output);
            fputc(0, output);
            fputc(0, output);
            fputc(0, output);
            continue;
        }

        const char *pos = strchr(BASE85_CHARS, ch);
        if (!pos) {
            fprintf(stderr, "Invalid character: %c\n", ch);
            exit(1);
        }

        val = val * 85 + (pos - BASE85_CHARS);
        count++;

        if (count == 5) {
            for (int i = 3; i >= 0; i--) {
                fputc((val >> (i * 8)) & 0xFF, output);
            }
            val = 0;
            count = 0;
        }
    }

    // Handle remaining bytes
    if (count > 0) {
        val = val * (unsigned int)pow(85, 5 - count);
        for (int i = 3; i >= 4 - count; i--) {
            fputc((val >> (i * 8)) & 0xFF, output);
        }
    }
}

/* Base122 encoding */
static void encode_base122(FILE *input, FILE *output, int wrap_cols) {
    unsigned char buf[1];
    int cols = 0;

    while (!feof(input)) {
        int n = fread(buf, 1, 1, input);
        if (n == 0) break;

        // Simple base122-like encoding (not true base122)
        int hi = buf[0] / 122;
        int lo = buf[0] % 122;

        fputc(BASE122_CHARS[hi], output);
        fputc(BASE122_CHARS[lo], output);
        cols += 2;

        if (wrap_cols > 0 && cols >= wrap_cols) {
            fputc('\n', output);
            cols = 0;
        }
    }

    if (wrap_cols > 0 && cols > 0) {
        fputc('\n', output);
    }
}

static void decode_base122(FILE *input, FILE *output, int ignore_garbage) {
    int ch;
    int count = 0;
    int hi_val = 0;

    while ((ch = fgetc(input)) != EOF) {
        if (ignore_garbage && !strchr(BASE122_CHARS, ch)) {
            continue;
        }

        const char *pos = strchr(BASE122_CHARS, ch);
        if (!pos) {
            fprintf(stderr, "Invalid character: %c\n", ch);
            exit(1);
        }

        if (count == 0) {
            hi_val = pos - BASE122_CHARS;
            count = 1;
        } else {
            int val = hi_val * 122 + (pos - BASE122_CHARS);
            fputc(val & 0xFF, output);
            count = 0;
        }
    }
}

static base_type_t detect_base_from_name(const char *progname) {
    size_t len = strlen(progname);
    if (len >= 2) {
        const char *suffix = progname + len - 2;
        if (strcmp(suffix, "64") == 0) return BASE64;
        if (strcmp(suffix, "85") == 0) return BASE85;
        if (strcmp(suffix, "91") == 0) return BASE91;
    }
    if (len >= 3) {
        const char *suffix = progname + len - 3;
        if (strcmp(suffix, "122") == 0) return BASE122;
    }
    return BASE91; // default
}

static void process_file(const char *filename, options_t *opts) {
    FILE *input = stdin;
    if (strcmp(filename, "-") != 0) {
        input = fopen(filename, opts->binary ? "rb" : "r");
        if (!input) {
            perror(filename);
            exit(1);
        }
    }

    FILE *output = stdout;

    if (opts->decode) {
        switch (opts->base_type) {
            case BASE64:
                decode_base64(input, output, opts->ignore_garbage);
                break;
            case BASE85:
                decode_base85(input, output, opts->ignore_garbage);
                break;
            case BASE91:
                decode_base91(input, output, opts->ignore_garbage);
                break;
            case BASE122:
                decode_base122(input, output, opts->ignore_garbage);
                break;
        }
    } else {
        switch (opts->base_type) {
            case BASE64:
                encode_base64(input, output, opts->wrap_cols);
                break;
            case BASE85:
                encode_base85(input, output, opts->wrap_cols);
                break;
            case BASE91:
                encode_base91(input, output, opts->wrap_cols);
                break;
            case BASE122:
                encode_base122(input, output, opts->wrap_cols);
                break;
        }
    }

    if (input != stdin) {
        fclose(input);
    }
}

static void print_help(const char *progname) {
    printf("Usage: %s [OPTIONS] FILES...\n", progname);
    printf("\n");
    printf("If FILES is - or not specified, read from stdin.\n");
    printf("\n");
    printf("If argv[0] is ended with 64/85/91/122, that's the default encoding.\n");
    printf("(can be overrided by options)\n");
    printf("\n");
    printf("Options:\n");
    printf("  -b, --binary         input is binary\n");
    printf("  -t, --text           input is text (default)\n");
    printf("  -d, --decode         decode data\n");
    printf("  -i, --ignore-garbage when decoding, ignore non-alphabet characters\n");
    printf("  -w, --wrap=COLS      wrap encoded lines after COLS character (default 76).\n");
    printf("                       Use 0 to disable line wrapping.\n");
    printf("  -6, --base64         use base64 encoding\n");
    printf("  -8, --base85         use base85 encoding\n");
    printf("  -9, --base91         use base91 encoding\n");
    printf("  -B, --base122        use base122 encoding\n");
    printf("  -h, --help           display this help and exit\n");
    printf("      --version        output version information and exit\n");
}

static void print_version() {
    printf("base91 1.0.0\n");
    printf("Written by Lenik\n");
}

int main(int argc, char *argv[]) {
    options_t opts = {
        .binary = 0,
        .decode = 0,
        .ignore_garbage = 0,
        .wrap_cols = 76,
        .base_type = detect_base_from_name(argv[0]),
        .files = NULL,
        .file_count = 0
    };

    static struct option long_options[] = {
        {"binary", no_argument, 0, 'b'},
        {"text", no_argument, 0, 't'},
        {"decode", no_argument, 0, 'd'},
        {"ignore-garbage", no_argument, 0, 'i'},
        {"wrap", required_argument, 0, 'w'},
        {"base64", no_argument, 0, '6'},
        {"base85", no_argument, 0, '8'},
        {"base91", no_argument, 0, '9'},
        {"base122", no_argument, 0, 'B'},
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 0},
        {0, 0, 0, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "btdiw:68B9h", long_options, NULL)) != -1) {
        switch (opt) {
            case 'b':
                opts.binary = 1;
                break;
            case 't':
                opts.binary = 0;
                break;
            case 'd':
                opts.decode = 1;
                break;
            case 'i':
                opts.ignore_garbage = 1;
                break;
            case 'w':
                opts.wrap_cols = atoi(optarg);
                break;
            case '6':
                opts.base_type = BASE64;
                break;
            case '8':
                opts.base_type = BASE85;
                break;
            case '9':
                opts.base_type = BASE91;
                break;
            case 'B':
                opts.base_type = BASE122;
                break;
            case 'h':
                print_help(argv[0]);
                exit(0);
            case 0: // --version
                print_version();
                exit(0);
            default:
                fprintf(stderr, "Try '%s --help' for more information.\n", argv[0]);
                exit(1);
        }
    }

    // Collect remaining arguments as files
    opts.file_count = argc - optind;
    opts.files = argv + optind;

    // If no files specified, use stdin
    static char *stdin_arg = "-";
    if (opts.file_count == 0) {
        opts.files = &stdin_arg;
        opts.file_count = 1;
    }

    // Process each file
    for (int i = 0; i < opts.file_count; i++) {
        process_file(opts.files[i], &opts);
    }

    return 0;
}
