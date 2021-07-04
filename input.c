int a;

int fib(int n){
	return fib(n-1)+fib(n-2);
}

int main(){
	int x;
	
	a = 8;
	x = fib(a);
	
	println(a);
}


