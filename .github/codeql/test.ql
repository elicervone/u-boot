/**
 * @kind path-problem
 */

import cpp
import semmle.code.cpp.dataflow.TaintTracking

class NetworkByteSwap extends Expr {
  NetworkByteSwap() {
    exists(MacroInvocation inv |
      inv.getMacro().getName().regexpMatch("ntoh(s|l|ll)") and
      this = inv.getExpr()
    )
  }
}

module MyConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    source.asExpr() instanceof NetworkByteSwap
  }

  predicate isSink(DataFlow::Node sink) {
    exists (FunctionCall call
    | sink.asExpr() = call.getArgument(2) and
      call.getTarget().getName() = "memcpy"
      )
  }

  predicate isBarrier(DataFlow::Node node){
    exists(BinaryOperation op |
      op.getOperator() in ["<", "<=", ">", ">="] and
      op.getAnOperand() = node.asExpr()
    )
  }
}

module MyTaint = TaintTracking::Global<MyConfig>;
import MyTaint::PathGraph

from MyTaint::PathNode source, MyTaint::PathNode sink
where MyTaint::flowPath(source, sink) 
select sink, source, sink, "Network byte swap flows to memcpy"
