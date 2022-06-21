	while (text[++i]) {
		FILE *ptr;
		char ch;
		ptr = fopen("/home/jonas/icons_1.txt", "r");
		if (ptr == NULL) printf("Fail...");
		do{
			ch = fgetc(ptr);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeWarn]); */
			char buf[] = "#8ec07c";
			drw_clr_create(drw, &drw->scheme[ColFg], buf);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;
			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);
			}
		} while (ch != EOF);
		fclose(ptr);

		FILE *ptr2;
		char ch2;
		ptr2 = fopen("/home/jonas/icons_3.txt", "r");
		if (ptr2 == NULL) printf("Fail...");
		do{
			ch2 = fgetc(ptr2);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch2 && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeUrgent]); */
			char buf2[] = "#FF00FF";
			drw_clr_create(drw, &drw->scheme[ColFg], buf2);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;

			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);

			}
		} while (ch != EOF);
		fclose(ptr);

	}
	while (text[++i]) {
		FILE *ptr;
		char ch;
		ptr = fopen("/home/jonas/icons_1.txt", "r");
		if (ptr == NULL) printf("Fail...");
		do{
			ch = fgetc(ptr);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeWarn]); */
			char buf[] = "#8ec07c";
			drw_clr_create(drw, &drw->scheme[ColFg], buf);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;
			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);
			}
		} while (ch != EOF);
		fclose(ptr);

		FILE *ptr2;
		char ch2;
		ptr2 = fopen("/home/jonas/icons_3.txt", "r");
		if (ptr2 == NULL) printf("Fail...");
		do{
			ch2 = fgetc(ptr2);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch2 && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeUrgent]); */
			char buf2[] = "#FF00FF";
			drw_clr_create(drw, &drw->scheme[ColFg], buf2);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;

			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);

			}
		} while (ch != EOF);
		fclose(ptr);

	}
	while (text[++i]) {
		FILE *ptr;
		char ch;
		ptr = fopen("/home/jonas/icons_1.txt", "r");
		if (ptr == NULL) printf("Fail...");
		do{
			ch = fgetc(ptr);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeWarn]); */
			char buf[] = "#8ec07c";
			drw_clr_create(drw, &drw->scheme[ColFg], buf);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;
			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);
			}
		} while (ch != EOF);
		fclose(ptr);

		FILE *ptr2;
		char ch2;
		ptr2 = fopen("/home/jonas/icons_3.txt", "r");
		if (ptr2 == NULL) printf("Fail...");
		do{
			ch2 = fgetc(ptr2);
			/* printf("%c %d \n", ch, ch); */
			if (text[i] == ch2 && !isCode) {
		/* if ((int)(text[i] == -17 && !isCode)) { */

			/* drw_setscheme(drw, scheme[SchemeUrgent]); */
			char buf2[] = "#FF00FF";
			drw_clr_create(drw, &drw->scheme[ColFg], buf2);
			isCode = 1;

			w = TEXTW(text) - lrpad;
			drw_text(drw, x, 0, w, bh, 0, text, 0);
			x += w;

			text = text + i + 1;
			i=-1;
			isCode = 0;
			drw_setscheme(drw, scheme[SchemeNorm]);

			}
		} while (ch != EOF);
		fclose(ptr);
	}
