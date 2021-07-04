int fib[10];

int fibonacci(int n){
	if(fib[n-1]==0)
		fib[n-1] = fibonacci(n-1);
	if(fib[n-2]==0)
		fib[n-2] = fibonacci(n-2);
	fib[n] = fib[n-1]+fib[n-2];
	return fib[n];
}

int main(){
	int x,i;
	
	fib[0]=1;
	fib[1]=1;
	for(i=2;i<10;i++){
		fib[i]=0;
	}
	
	x = 9;
	x = fibonacci(x);
	
	for(i=0;i<10;i++){
		int y;
		y = fib[i];
		println(y);
	}

}
