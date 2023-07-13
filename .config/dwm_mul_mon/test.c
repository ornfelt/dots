#include <stdio.h>
#include <string.h>

int main()
{
    char s[1000];
    int i, alphabets=0, digits=0, specialchars=0;
    /* printf("Enter string"); */
    /* gets(s); */

    FILE *ptr;
    char ch;
    ptr = fopen("/home/jonas/test.txt", "r");
    if (ptr == NULL) printf("Fail...");
    do{
        ch = fgetc(ptr);
        /* printf("%c", ch); */
        /* printf("%c %d \n", ch, ch); */
        printf("%d\n", ch);
        /* printf("%d", ch); */
    } while (ch != EOF);
    fclose(ptr);

    /* for(int i = 0;s[i]; i++){ */
    /*     if((s[i] >= 65 && s[i] <= 90) || (s[i] >= 97 && s[i] <= 122)) */
    /*         alphabets++; */
    /*     else if (s[i]>48 && s[i] <=57) digits++; */
    /*     else specialchars++; */

    /* } */
    /* printf("Alphas = %d}n", alphabets); */
    /* printf("Digits = %d\n", digits); */
    /* printf("Spec chars = %d", specialchars); */

    return 0;
}
