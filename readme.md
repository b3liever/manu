# Manu — Nim Matrix Numeric library

Manu is a pure Nim library, no external dependencies to BLAS frameworks.
Supports constructing and manipulating only real, dense matrices.
It started as a port of [JAMA](https://math.nist.gov/javanumerics/jama/)
library, and is adapted to Nim programming paradigm and specific performace considerations.

What is supported:

- Compute solutions of simultaneous linear equations, determinants, inverses and other matrix functions.
- Arithmetic operators are overloaded to support matrices.
  * Broadcast scalars, column and row vectors to work with matrices.
- Destructors, with sink annotations, copies can be avoided in some cases. Compile with ``--seqsv2:on`` switch.

API [documentation](https://b3liever.github.io/manu/)

## Examples

In the examples directory you will find the following:

1. [two layer neural network](https://github.com/b3liever/manu/blob/master/examples/neural.nim)
2. [stress state analysis script](https://github.com/b3liever/manu/blob/master/examples/mohr.nim)

showcasing what can already be done.

### example2.nim

```nim
   import manu
   # Solve a linear system A x = b and compute the residual norm, ||b - A x||.
   let vals = @[@[1.0, 2.0, 3.0], @[4.0, 5.0, 6.0], @[7.0, 8.0, 10.0]]
   let A = matrix(vals)
   let b = randMatrix(3, 1)
   let x = A.solve(b)
   let r = A * x - b
   let rnorm = r.normInf()
   echo("x =\n", x)
   echo("residual norm = ", rnorm)
```

Output:

```
x =
⎡-918.9217543597e-3⎤
⎢      2.1952979104⎥
⎣     -1.0796593055⎦
residual norm = 1.554312234475219e-15
```

## Matrix decompositions

Five matrix decompositions are used to compute solutions of simultaneous linear equations,
determinants, inverses and other matrix functions. Theses are:

- Cholesky Decomposition of symmetric, positive definite matrices
- LU Decomposition (Gaussian elimination) of rectangular matrices
- QR Decomposition of rectangular matrices
- Eigenvalue Decomposition of both symmetric and nonsymmetric square matrices
- Singular Value Decomposition of rectangular matrices

## Broadcasting

It is implemented with the help of two ``distinct`` types ``RowVector`` and ``ColVector``.
Any compatible matrix can be casted to these i.e: ``ColVector(ones(5, 1))`` and when
doing arithmetic with Matrices, will be broadcasted to the correct dimensions, so:

```nim
var a = matrix(1, 5, 2.0)
let b = ones(2, 1)
echo ColVector(b) + RowVector(a)
echo 2.0 + a
```

Results in:

```
⎡3  3  3  3  3⎤
⎣3  3  3  3  3⎦
⎡4  4  4  4  4⎤
```

If the casted matrix is not a vector an ``AssertionError`` will be thrown at runtime.

The correct paradigm of usage is to first initialize a matrix, i.e ``let a = ones(1, 5)`` and cast it
to ``RowVector`` where broadcasting is needed: ``RowVector(a) + zeros(5, 5)``.
This system is designed to be more explicit, and since it is type-checked, work well with ``sink`` optimizations.

## Feature improvements
- Add more tests
- Incorporate usefull additions from [Apache Commons Math](https://github.com/apache/commons-math)

## License
This library is distributed under the MIT license. For more information see `copying.txt`.
