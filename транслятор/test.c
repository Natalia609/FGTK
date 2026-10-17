main() {
int x = 81;
int op = x;
int res = 0;
int one = 1073741824;

while (one > op) {one = one / 4; }
while (one != 0) {
	if (op >= res + one) {
		op = op - (res + one);
		res = res + (one * 2);
	}
	res = res / 2;
	one = one / 4;

}
printf(res);
}