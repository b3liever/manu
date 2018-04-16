##
## Morpheus - Nim Matrix module.
## =============================
##
## The Matrix object provides the fundamental operations of numerical
## linear algebra. Various constructors create Matrices from two dimensional
## arrays of double precision floating point numbers. Various "gets" and
## "sets" provide access to submatrices and matrix elements.  Several methods 
## implement basic matrix arithmetic, including matrix addition and
## multiplication, matrix norms, and element-by-element array operations.
## Methods for reading and printing matrices are also included. All the
## operations in this version of the Matrix Object involve real matrices.
## Complex matrices may be handled in a future version.
##
## Five fundamental matrix decompositions, which consist of pairs or triples
## of matrices, permutation vectors, and the like, produce results in five
## decomposition classes.  These decompositions are accessed by the Matrix
## class to compute solutions of simultaneous linear equations, determinants,
## inverses and other matrix functions.  The five decompositions are:
##
## - Cholesky Decomposition of symmetric, positive definite matrices.
## - LU Decomposition of rectangular matrices.
## - QR Decomposition of rectangular matrices.
## - Singular Value Decomposition of rectangular matrices.
## - Eigenvalue Decomposition of both symmetric and nonsymmetric square matrices.
##
## **Example of use:**
##
## .. code-block:: nim
##    import morpheus
##    # Solve a linear system A x = b and compute the residual norm, ||b - A x||.
##    let vals = @[@[1.0, 2.0, 3.0], @[4.0, 5.0, 6.0], @[7.0, 8.0, 10.0]]
##    let A = matrix(vals)
##    let b = randMatrix(3, 1)
##    let x = A.solve(b)
##    let r = A * x - b
##    let rnorm = r.normInf()
##
import math, random, strutils

template checkBounds(cond: untyped, msg = "") =
   when compileOption("boundChecks"):
      {.line.}:
         if not cond:
            raise newException(IndexError, msg)

template newData() =
   newSeq(result.data, result.m)
   for i in 0 ..< result.m:
      newSeq(result.data[i], result.n)

type Matrix* = object
   # Array for internal storage of elements.
   data*: seq[seq[float]]
   # Row and column dimensions.
   m*, n*: int

proc matrix*(m, n: int): Matrix =
   ## Construct an m-by-n matrix of zeros. 
   result.m = m
   result.n = n
   newData()

proc matrix*(m, n: int, s: float): Matrix =
   ## Construct an m-by-n constant matrix.
   result.m = m
   result.n = n
   newData()
   for i in 0 ..< m:
      for j in 0 ..< n:
         result.data[i][j] = s

proc matrix*(data: seq[seq[float]]): Matrix =
   ## Construct a matrix from a 2-D array.
   result.m = data.len
   result.n = data[0].len
   when compileOption("assertions"):
      for i in 0 ..< result.m:
         assert(data[i].len == result.n, "All rows must have the same length.")
   result.data = data

proc matrix*(data: seq[float], m: int): Matrix =
   ## Construct a matrix from a one-dimensional packed array.
   ## ``data`` is a one-dimensional array of float, packed by columns (ala Fortran).
   ## Array length must be a multiple of ``m``.
   result.m = m
   result.n = if m != 0: data.len div m else: 0
   assert result.m * result.n == data.len, "Array length must be a multiple of m."
   newData()
   for i in 0 ..< m:
      for j in 0 ..< result.n:
         result.data[i][j] = data[i + j * m]

proc getArray*(m: Matrix): seq[seq[float]] =
   ## Copy the internal two-dimensional array.
   result = m.data

proc getColumnPacked*(m: Matrix): seq[float] =
   ## Make a one-dimensional column packed copy of the internal array.
   newSeq(result, m.m * m.n)
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result[i + j * m.m] = m.data[i][j]

proc getRowPacked*(m: Matrix): seq[float] =
   ## Make a one-dimensional row packed copy of the internal array.
   newSeq(result, m.m * m.n)
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result[i * m.n + j] = m.data[i][j]

proc rowDimension*(m: Matrix): int =
   ## Get row dimension.
   m.m

proc columnDimension*(m: Matrix): int =
   ## Get column dimension.
   m.n

proc `[]`*(m: Matrix, i, j: int): float =
   ## Get a single element.
   m.data[i][j]

proc `[]`*(m: Matrix, r, c: Slice[int]): Matrix =
   ## Get a submatrix,
   ## ``m[i0 .. i1, j0 .. j1]``
   checkBounds(r.a >= 0 and r.b < m.m, "Submatrix dimensions")
   checkBounds(c.a >= 0 and c.b < m.n, "Submatrix dimensions")
   result.m = r.b - r.a + 1
   result.n = c.b - c.a + 1
   newData()
   for i in r.a .. r.b:
      for j in c.a .. c.b:
         result.data[i - r.a][j - c.a] = m.data[i][j]

proc `[]`*(m: Matrix, r, c: openarray[int]): Matrix =
   ## Get a submatrix,
   ## ``m[[0, 2, 3, 4], [1, 2, 3, 4]]``
   checkBounds(r.len <= m.m, "Submatrix dimensions")
   checkBounds(c.len <= m.n, "Submatrix dimensions")
   result.m = r.len
   result.n = c.len
   newData()
   for i in 0 ..< r.len:
      for j in 0 ..< c.len:
         result.data[i][j] = m.data[r[i]][c[j]]

proc `[]`*(m: Matrix, r: Slice[int], c: openarray[int]): Matrix =
   ## Get a submatrix,
   ## ``m[i0 .. i1, [0, 2, 3, 4]]``
   checkBounds(r.a >= 0 and r.b < m.m, "Submatrix dimensions")
   checkBounds(c.len <= m.n, "Submatrix dimensions")
   result.m = r.b - r.a + 1
   result.n = c.len
   newData()
   for i in r.a .. r.b:
      for j in 0 ..< c.len:
         result.data[i - r.a][j] = m.data[i][c[j]]

proc `[]`*(m: Matrix, r: openarray[int], c: Slice[int]): Matrix =
   ## Get a submatrix,
   ## ``m[[0, 2, 3, 4], j0 .. j1]``
   checkBounds(r.len <= m.m, "Submatrix dimensions")
   checkBounds(c.a >= 0 and c.b < m.n, "Submatrix dimensions")
   result.m = r.len
   result.n = c.b - c.a + 1
   newData()
   for i in 0 ..< r.len:
      for j in c.a .. c.b:
         result.data[i][j - c.a] = m.data[r[i]][j]

proc `[]=`*(m: var Matrix, i, j: int, s: float) =
   ## Set a single element.
   m.data[i][j] = s

proc `[]=`*(m: var Matrix, r, c: Slice[int], a: Matrix) =
   ## Set a submatrix,
   ## ``m[i0 .. i1, j0 .. j1] = a``
   checkBounds(r.b - r.a + 1 == a.m, "Submatrix dimensions")
   checkBounds(c.b - c.a + 1 == a.n, "Submatrix dimensions")
   for i in r.a .. r.b:
      for j in c.a .. c.b:
         m.data[i][j] = a.data[i - r.a][j - c.a]

proc `[]=`*(m: var Matrix, r, c: openarray[int], a: Matrix) =
   ## Set a submatrix
   checkBounds(r.len == a.m, "Submatrix dimensions")
   checkBounds(c.len == a.n, "Submatrix dimensions")
   for i in 0 ..< r.len:
      for j in 0 ..< c.len:
         m.data[r[i]][c[j]] = a.data[i][j]

proc `[]=`*(m: var Matrix, r: openarray[int], c: Slice[int], a: Matrix) =
   ## Set a submatrix,
   ## ``m[[0, 2, 3, 4], j0 .. j1] = a``
   checkBounds(r.len == a.m, "Submatrix dimensions")
   checkBounds(c.b - c.a + 1 == a.n, "Submatrix dimensions")
   for i in 0 ..< r.len:
      for j in c.a .. c.b:
         m.data[r[i]][j] = a.data[i][j - c.a]

proc `[]=`*(m: var Matrix, r: Slice[int], c: openarray[int], a: Matrix) =
   ## Set a submatrix,
   ## ``m[i0 .. i1, [0, 2, 3, 4]] = a``
   checkBounds(r.b - r.a + 1 == a.m, "Submatrix dimensions")
   checkBounds(c.len == a.n, "Submatrix dimensions")
   for i in r.a .. r.b:
      for j in 0 ..< c.len:
         m.data[i][c[j]] = a.data[i - r.a][j]

proc `-`*(m: Matrix): Matrix =
   ## Unary minus
   result.m = m.m
   result.n = m.n
   newData()
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result.data[i][j] = -m.data[i][j]

proc `+`*(a, b: Matrix): Matrix =
   ## ``C = A + B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   result.m = a.m
   result.n = a.n
   newData()
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         result.data[i][j] = a.data[i][j] + b.data[i][j]

proc `+=`*(a: var Matrix, b: Matrix) =
   ## ``A = A + B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         a.data[i][j] = a.data[i][j] + b.data[i][j]

proc `-`*(a, b: Matrix): Matrix =
   ## ``C = A - B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   result.m = a.m
   result.n = a.n
   newData()
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         result.data[i][j] = a.data[i][j] - b.data[i][j]

proc `-=`*(a: var Matrix, b: Matrix) =
   ## ``A = A - B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         a.data[i][j] = a.data[i][j] - b.data[i][j]

proc `.*`*(a, b: Matrix): Matrix =
   ## Element-by-element multiplication, ``C = A.*B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   result.m = a.m
   result.n = a.n
   newData()
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         result.data[i][j] = a.data[i][j] * b.data[i][j]

proc `.*=`*(a: var Matrix, b: Matrix) =
   ## Element-by-element multiplication in place, ``A = A.*B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         a.data[i][j] = a.data[i][j] * b.data[i][j]

proc `./`*(a, b: Matrix): Matrix =
   ## Element-by-element right division, ``C = A./B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   result.m = a.m
   result.n = a.n
   newData()
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         result.data[i][j] = a.data[i][j] / b.data[i][j]

proc `./=`*(a: var Matrix, b: Matrix) =
   ## Element-by-element right division in place, ``A = A./B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         a.data[i][j] = a.data[i][j] / b.data[i][j]

proc `.\`*(a, b: Matrix): Matrix =
   ## Element-by-element left division, ``C = A.\B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   result.m = a.m
   result.n = a.n
   newData()
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         result.data[i][j] = b.data[i][j] / a.data[i][j]

proc `.\=`*(a: var Matrix, b: Matrix) =
   ## Element-by-element left division in place, ``A = A.\B``
   assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
   for i in 0 ..< a.m:
      for j in 0 ..< a.n:
         a.data[i][j] = b.data[i][j] / a.data[i][j]

proc `*`*(m: Matrix, s: float): Matrix =
   ## Multiply a matrix by a scalar, ``C = s*A``
   result.m = m.m
   result.n = m.n
   newData()
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result.data[i][j] = s * m.data[i][j]

proc `*=`*(m: var Matrix, s: float) =
   ## Multiply a matrix by a scalar in place, ``A = s*A``
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         m.data[i][j] = s * m.data[i][j]

proc `*`*(a, b: Matrix): Matrix =
   ## Linear algebraic matrix multiplication, ``A * B``
   assert(b.m == a.n, "Matrix inner dimensions must agree.")
   result.m = a.m
   result.n = b.n
   newData()
   var b_colj = newSeq[float](a.n)
   for j in 0 ..< b.n:
      for k in 0 ..< a.n:
         b_colj[k] = b.data[k][j]
      for i in 0 ..< a.m:
         var a_rowi = unsafeAddr a.data[i]
         var s = 0.0
         for k in 0 ..< a.n:
            s += a_rowi[k] * b_colj[k]
         result.data[i][j] = s

proc transpose*(m: Matrix): Matrix =
   ## Matrix transpose
   result.m = m.n
   result.n = m.m
   newData()
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result.data[j][i] = m.data[i][j]

proc identity*(m, n: int): Matrix =
   ## Generate identity matrix,
   ## returns An m-by-n matrix with ones on the diagonal and zeros elsewhere.
   result.m = m
   result.n = n
   newData()
   for i in 0 ..< m:
      for j in 0 ..< n:
         if i == j:
            result.data[i][j] = 1.0

proc norm1*(m: Matrix): float =
   ## One norm,
   ## returns maximum column sum.
   for j in 0 ..< m.n:
      var s = 0.0
      for i in 0 ..< m.m:
         s += abs(m.data[i][j])
      result = max(result, s)

proc normInf*(m: Matrix): float =
   ## Infinity norm,
   ## returns maximum row sum.
   for i in 0 ..< m.m:
      var s = 0.0
      for j in 0 ..< m.n:
         s += abs(m.data[i][j])
      result = max(result, s)

proc normF*(m: Matrix): float =
   ## Frobenius norm,
   ## returns sqrt of sum of squares of all elements.
   for i in 0 ..< m.m:
      for j in 0 ..< m.n:
         result = hypot(result, m.data[i][j])

proc trace*(m: Matrix): float =
   ## Matrix trace,
   ## returns the sum of the diagonal elements.
   for i in 0 ..< min(m.m, m.n):
      result += m.data[i][i]

proc randMatrix*(m, n: int): Matrix =
   ## Generate matrix with random elements,
   ## returns an m-by-n matrix with uniformly distributed random elements.
   result.m = m
   result.n = n
   newData()
   for i in 0 ..< m:
      for j in 0 ..< n:
         result.data[i][j] = rand(1.0)

proc columnFormat(s: seq[float]): seq[string] =
   result = newSeq[string](s.len)
   for i, v in s:
      result[i] = formatFloat(v, ffDecimal, 6)
   var lenLeft = newSeq[int](s.len)
   var maxLenLeft = 0
   for i, f in result:
      let index = f.find('.')
      lenLeft[i]  = index
      maxLenLeft = max(maxLenLeft, lenLeft[i])
   for i in 0 ..< s.len:
      result[i] = spaces(maxLenLeft  - lenLeft[i]) & result[i]

proc `$`*(m: Matrix): string =
   var cols: seq[seq[string]]
   newSeq(cols, m.m)
   for i in 0 ..< m.m:
      cols[i] = columnFormat(m.data[i])
   result = ""
   for j in 0 ..< m.n:
      if j == 0:
         result.add "⎡"
      elif j == m.n - 1:
         result.add "⎣"
      else:
         result.add "⎢"
      for i in 0 ..< m.m:
         if i != 0:
            result.add "  "
         result.add cols[i][j]
      if j == 0:
         result.add "⎤\n"
      elif j == m.n - 1:
         result.add "⎦\n"
      else:
         result.add "⎥\n"