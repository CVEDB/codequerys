/**
 * For internal use only.
 *
 * Defines shared code used by the NoSQL injection boosted query.
 */

import javascript
private import semmle.javascript.heuristics.SyntacticHeuristics
private import semmle.javascript.security.dataflow.NosqlInjectionCustomizations as Classic
private import AdaptiveThreatModeling as ATM
private import StandardEndpointLabels as StandardEndpointLabels
import EndpointTypes

module SinkEndpointFilter {
  class NosqlInjectionLabelTrainingSelectionCfg extends StandardEndpointLabels::LabelSelectionCfg {
    NosqlInjectionLabelTrainingSelectionCfg() { this = "NosqlInjectionLabelTrainingSelectionCfg" }

    override EndpointType getQuery() {
      result = any(NosqlInjectionSinkType t)
    }

    override StandardEndpointLabels::Reason classify(DataFlow::Node n) {
      none()
    }
  }

  /**
   * Provides a set of reasons why a given data flow node should be excluded as a sink candidate.
   *
   * If this predicate has no results for a sink candidate `n`, then we should treat `n` as an
   * effective sink.
   */
  string getAReasonSinkExcluded(DataFlow::Node sinkCandidate) {
    result =
      any(StandardEndpointLabels::Labels::EndpointLabeller l |
        l instanceof StandardEndpointLabels::Labels::LegacyReasonSinkExcludedEndpointLabeller or
        l instanceof StandardEndpointLabels::Labels::LegacyModeledDbAccessEndpointLabeller or
        l instanceof StandardEndpointLabels::Labels::LegacyModeledSinkEndpointLabeller or
        l instanceof StandardEndpointLabels::Labels::LegacyModeledStepSourceEndpointLabeller or
        l instanceof StandardEndpointLabels::Labels::LegacyModeledHttpEndpointLabeller
      ).getLabel(sinkCandidate)
    or
    // TODO move this comment, and update it, when improving the endpoint filters.
    //
    // Require NoSQL injection sink candidates to be (a) direct arguments to external library calls
    // or (b) heuristic sinks for NoSQL injection.
    //
    // ## Direct arguments to external library calls
    //
    // The `StandardEndpointFilters::flowsToArgumentOfLikelyExternalLibraryCall` endpoint filter
    // allows sink candidates which are within object literals or array literals, for example
    // `req.sendFile(_, { path: ENDPOINT })`.
    //
    // However, the NoSQL injection query deals differently with these types of sinks compared to
    // other security queries. Other security queries such as SQL injection tend to treat
    // `ENDPOINT` as the ground truth sink, but the NoSQL injection query instead treats
    // `{ path: ENDPOINT }` as the ground truth sink and defines an additional flow step to ensure
    // data flows from `ENDPOINT` to the ground truth sink `{ path: ENDPOINT }`.
    //
    // Therefore for the NoSQL injection boosted query, we must ignore sink candidates within object
    // literals or array literals, to avoid having multiple alerts for the same security
    // vulnerability (one FP where the sink is `ENDPOINT` and one TP where the sink is
    // `{ path: ENDPOINT }`). We accomplish this by directly testing that the sink candidate is an
    // argument of a likely external library call.
    //
    // ## Heuristic sinks
    //
    // We also allow heuristic sinks in addition to direct arguments to external library calls.
    // These are copied from the `HeuristicNosqlInjectionSink` class defined within
    // `codeql/javascript/ql/src/semmle/javascript/heuristics/AdditionalSinks.qll`.
    // We can't reuse the class because importing that file would cause us to treat these
    // heuristic sinks as known sinks.
    not sinkCandidate =
      StandardEndpointLabels::getALabeledEndpoint("legacy/likely-external-library-call/is")
          .(DataFlow::CallNode)
          .getAnArgument() and
    not (
      isAssignedToOrConcatenatedWith(sinkCandidate, "(?i)(nosql|query)") or
      isArgTo(sinkCandidate, "(?i)(query)")
    ) and
    result = "not a direct argument to a likely external library call or a heuristic sink"
  }
}

class NosqlInjectionAtmConfig extends ATM::AtmConfig {
  NosqlInjectionAtmConfig() { this = "NosqlInjectionATMConfig" }

  override predicate isKnownSource(DataFlow::Node source) {
    source instanceof Classic::NosqlInjection::Source or Classic::TaintedObject::isSource(source, _)
  }

  override predicate isKnownSink(DataFlow::Node sink) { sink instanceof Classic::NosqlInjection::Sink }

  override predicate isEffectiveSink(DataFlow::Node sinkCandidate) {
    not exists(SinkEndpointFilter::getAReasonSinkExcluded(sinkCandidate))
  }

  override ATM::EndpointType getASinkEndpointType() { result instanceof ATM::NosqlInjectionSinkType }
}

/** Holds if src -> trg is an additional flow step in the non-boosted NoSql injection security query. */
predicate isBaseAdditionalFlowStep(
  DataFlow::Node src, DataFlow::Node trg, DataFlow::FlowLabel inlbl, DataFlow::FlowLabel outlbl
) {
  Classic::TaintedObject::step(src, trg, inlbl, outlbl)
  or
  // additional flow step to track taint through NoSQL query objects
  inlbl = Classic::TaintedObject::label() and
  outlbl = Classic::TaintedObject::label() and
  exists(NoSql::Query query, DataFlow::SourceNode queryObj |
    queryObj.flowsTo(query) and
    queryObj.flowsTo(trg) and
    src = queryObj.getAPropertyWrite().getRhs()
  )
}

/**
 * Gets a value that is (transitively) written to `query`, where `query` is a NoSQL sink.
 *
 * This predicate allows us to propagate data flow through property writes and array constructors
 * within a query object, enabling the security query to pick up NoSQL injection vulnerabilities
 * involving more complex queries.
 */
DataFlow::Node getASubexpressionWithinQuery(DataFlow::Node query) {
  any(NosqlInjectionAtmConfig cfg).isEffectiveSink(query) and
  exists(DataFlow::SourceNode receiver |
    receiver = [getASubexpressionWithinQuery(query), query].getALocalSource()
  |
    result =
      [receiver.getAPropertyWrite().getRhs(), receiver.(DataFlow::ArrayCreationNode).getAnElement()]
  )
}

/**
 * A taint-tracking configuration for reasoning about NoSQL injection vulnerabilities.
 *
 * This is largely a copy of the taint tracking configuration for the standard NoSQL injection
 * query, except additional ATM sinks have been added and the additional flow step has been
 * generalised to cover the sinks predicted by ATM.
 */
class Configuration extends TaintTracking::Configuration {
  Configuration() { this = "NosqlInjectionATM" }

  override predicate isSource(DataFlow::Node source) { source instanceof Classic::NosqlInjection::Source }

  override predicate isSource(DataFlow::Node source, DataFlow::FlowLabel label) {
    Classic::TaintedObject::isSource(source, label)
  }

  override predicate isSink(DataFlow::Node sink, DataFlow::FlowLabel label) {
    sink.(Classic::NosqlInjection::Sink).getAFlowLabel() = label
    or
    // Allow effective sinks to have any taint label
    any(NosqlInjectionAtmConfig cfg).isEffectiveSink(sink)
  }

  override predicate isSanitizer(DataFlow::Node node) {
    super.isSanitizer(node) or
    node instanceof Classic::NosqlInjection::Sanitizer
  }

  override predicate isSanitizerGuard(TaintTracking::SanitizerGuardNode guard) {
    guard instanceof Classic::TaintedObject::SanitizerGuard
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node src, DataFlow::Node trg, DataFlow::FlowLabel inlbl, DataFlow::FlowLabel outlbl
  ) {
    // additional flow steps from the base (non-boosted) security query
    isBaseAdditionalFlowStep(src, trg, inlbl, outlbl)
    or
    // relaxed version of previous step to track taint through unmodeled NoSQL query objects
    any(NosqlInjectionAtmConfig cfg).isEffectiveSink(trg) and
    src = getASubexpressionWithinQuery(trg)
  }
}
