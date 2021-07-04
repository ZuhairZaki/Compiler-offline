
int fib(int n){
	if(n==1||n==2)
		return 1;
	return fib(n-1)+fib(n-2);
}

int main(){
	int x;
	
	x = 8;
	println(x);
	
	x = fib(x);
	
	println(x);
}


