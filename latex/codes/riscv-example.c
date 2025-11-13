#include <stdio.h>
#include <stdlib.h>

#define MAX_N 100

int buf[MAX_N];

void do_sort(int a[], int n)
{
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
	    if (a[i] > a[j]) {
	        // swap a[i],a[j]
	        a[i] ^= a[j];
		a[j] ^= a[i];
	        a[i] ^= a[j];
	    }
	}
    }
}

int main()
{
    int n;
    scanf("%d", &n);

    int t = n;
    while (t--) {
        scanf("%d",&buf[t]);
    }

    do_sort(buf,n);

    for (int i = 0; i < n; ++i) {
        printf("%d ",buf[i]);
    }
    printf("\n");
    return 0;
}
