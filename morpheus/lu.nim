## LU Decomposition.
##
## For an m-by-n matrix A with m >= n, the LU decomposition is an m-by-n
## unit lower triangular matrix L, an n-by-n upper triangular matrix U,
## and a permutation vector piv of length m so that A(piv,:) = L*U.
## If m < n, then L is m-by-m and U is m-by-n.
##
## The LU decompostion with pivoting always exists, even if the matrix is
## singular, so the constructor will never fail. The primary use of the
## LU decomposition is in the solution of square systems of simultaneous
## linear equations. This will fail if isNonsingular() returns false.
import "./matrix"

type LUDecomposition* = object
   # Array for internal storage of decomposition.
   lu: Matrix
   # Internal storage of pivot vector.
   piv: seq[int]
   # Pivot sign.
   pivsign: int

proc lu*(a: Matrix): LUDecomposition =
   ## LU Decomposition
   ## Structure to access L, U and piv.
   ## param ``a``: Rectangular matrix
   # Use a "left-looking", dot-product, Crout/Doolittle algorithm.
   let m = a.m
   let n = a.n
   result.lu = a
   result.piv = newSeq[int](m)
   for i in 0 ..< m:
      result.piv[i] = i
   result.pivsign = 1
   var luColj = newSeq[float](m)
   # Outer loop.
   for j in 0 ..< n:
      # Make a copy of the j-th column to localize references.
      for i in 0 ..< m:
         luColj[i] = result.lu[i, j]
      # Apply previous transformations.
      for i in 0 ..< m:
         var luRowi = result.lu.mgetRow(i)
         # Most of the time is spent in the following dot product.
         let kmax = min(i, j)
         var s = 0.0
         for k in 0 ..< kmax:
            s += luRowi[k] * luColj[k]
         luColj[i] -= s
         luRowi[j] = luColj[i]
      # Find pivot and exchange if necessary.
      var p = j
      for i in j + 1 ..< m:
         if abs(luColj[i]) > abs(luColj[p]):
            p = i
      if p != j:
         for k in 0 ..< n:
            swap(result.lu[p, k], result.lu[j, k])
         swap(result.piv[p], result.piv[j])
         result.pivsign = -result.pivsign
      # Compute multipliers.
      if j < m and result.lu[j, j] != 0.0:
         for i in j + 1 ..< m:
            result.lu[i, j] /= result.lu[j, j]

proc isNonsingular*(l: LUDecomposition): bool =
   ## Is the matrix nonsingular?
   ## return: true if U, and hence A, is nonsingular.
   for j in 0 ..< l.lu.n:
      if l.lu[j, j] == 0.0:
         return false
   return true

proc getL*(l: LUDecomposition): Matrix =
   ## Return lower triangular factor.
   let m = l.lu.m
   let n = l.lu.n
   result = matrix(m, n)
   for i in 0 ..< m:
      for j in 0 ..< n:
         if i > j:
            result[i, j] = l.lu[i, j]
         elif i == j:
            result[i, j] = 1.0

proc getU*(l: LUDecomposition): Matrix =
   ## Return upper triangular factor.
   let m = l.lu.m
   let n = l.lu.n
   result = matrix(m, n)
   for i in 0 ..< n:
      for j in 0 ..< n:
         if i <= j:
            result[i, j] = l.lu[i, j]

proc getPivot*(l: LUDecomposition): seq[int] =
   ## Return pivot permutation vector.
   l.piv

proc getFloatPivot*(l: LUDecomposition): seq[float] =
   ## Return pivot permutation vector as a one-dimensional double array.
   let m = l.lu.m
   result = newSeq[float](m)
   for i in 0 ..< m:
      result[i] = float(l.piv[i])

proc det*(l: LUDecomposition): float =
   ## Determinant
   assert(l.lu.m == l.lu.n, "Matrix must be square.")
   result = float(l.pivsign)
   for j in 0 ..< l.lu.n:
      result *= l.lu[j, j]

proc solve*(l: LUDecomposition, b: Matrix): Matrix =
   ## Solve ``A*X = B``.
   ## parameter ``B``: A Matrix with as many rows as A and any number of columns.
   ## return: X so that ``L*U*X = B(piv,:)``
   let m = l.lu.m
   let n = l.lu.n
   let nx = b.n
   assert(b.m == m, "Matrix row dimensions must agree.")
   assert(l.isNonsingular, "Matrix is singular.")
   # Copy right hand side with pivoting
   result = b[l.piv, 0 ..< nx]
   # Solve L*Y = B(piv,:)
   for k in 0 ..< n:
      for i in k + 1 ..< n:
         for j in 0 ..< nx:
            result[i, j] -= result[k, j] * l.lu[i, k]
   # Solve U*X = Y
   for k in countdown(n - 1, 0):
      for j in 0 ..< nx:
         result[k, j] /= l.lu[k, k]
      for i in 0 ..< k:
         for j in 0 ..< nx:
            result[i, j] -= result[k, j] * l.lu[i, k]
