// generated by codegen/codegen.py
import codeql.swift.elements.expr.Expr

class TupleExprBase extends @tuple_expr, Expr {
  override string toString() { result = "TupleExpr" }

  Expr getElement(int index) {
    exists(Expr x |
      tuple_expr_elements(this, index, x) and
      result = x.resolve()
    )
  }

  Expr getAnElement() { result = getElement(_) }

  int getNumberOfElements() { result = count(getAnElement()) }
}
