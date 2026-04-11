function main(): Int { 
    return sum(40, 1);
}

function sum(a:Int, ?b:Int = 0):Int {
    return a + b;
}