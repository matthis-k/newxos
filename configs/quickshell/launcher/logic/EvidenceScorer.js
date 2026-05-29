.pragma library
Qt.include("FieldNormalizer.js")

var EVIDENCE_WEIGHTS = {
  baseline: -1.0,
  accumulated: 1.0,
  depthReward: 0,
  actionBonus: 0.5,
  dangerousAction: -1.5
};

function sigmoid(x) {
  return 1 / (1 + Math.exp(-x));
}

function computeEvidenceBreakdown(candidate, parsedQuery, context) {
  var queryTokens = (parsedQuery.tokens || []).slice();
  var allTokens = [];
  for (var qi = 0; qi < queryTokens.length; qi += 1) {
    var sub = tokenize(queryTokens[qi]);
    for (var si = 0; si < sub.length; si += 1)
      allTokens.push(sub[si]);
  }

  if (allTokens.length === 0) {
    return {
      totalEvidence: 0,
      score: 1,
      breakdown: []
    };
  }

  var tokenScores = candidate.tokenScores || {};
  var accumulated = 0;
  for (var ti = 0; ti < allTokens.length; ti += 1) {
    accumulated += tokenScores[allTokens[ti]] || 0;
  }

  var depth = candidate.depth || 0;
  var hasAction = !!candidate.action;
  var dangerous = !!candidate.dangerous;

  var totalEvidence =
    EVIDENCE_WEIGHTS.baseline +
    EVIDENCE_WEIGHTS.accumulated * accumulated +
    EVIDENCE_WEIGHTS.depthReward * depth +
    (hasAction ? EVIDENCE_WEIGHTS.actionBonus : 0) +
    (dangerous ? EVIDENCE_WEIGHTS.dangerousAction : 0);

  return {
    totalEvidence: totalEvidence,
    score: sigmoid(totalEvidence),
    breakdown: [
      { name: "baseline", value: EVIDENCE_WEIGHTS.baseline, weight: 1, contribution: EVIDENCE_WEIGHTS.baseline },
      { name: "accumulated", value: accumulated, weight: EVIDENCE_WEIGHTS.accumulated, contribution: EVIDENCE_WEIGHTS.accumulated * accumulated },
      { name: "depthReward", value: depth, weight: EVIDENCE_WEIGHTS.depthReward, contribution: EVIDENCE_WEIGHTS.depthReward * depth },
      { name: "actionBonus", value: hasAction ? 1 : 0, weight: EVIDENCE_WEIGHTS.actionBonus, contribution: hasAction ? EVIDENCE_WEIGHTS.actionBonus : 0 },
      { name: "dangerous", value: dangerous ? 1 : 0, weight: EVIDENCE_WEIGHTS.dangerousAction, contribution: dangerous ? EVIDENCE_WEIGHTS.dangerousAction : 0 }
    ]
  };
}

function computeScore(candidate, parsedQuery, context) {
  var evidence = computeEvidenceBreakdown(candidate, parsedQuery, context);
  return evidence.score;
}

function isAboveThreshold(candidate, bestScore) {
  var minAbs = 0.35;
  var minRel = 0.30;

  if (candidate.score < minAbs)
    return false;

  if (bestScore > 0 && candidate.score < bestScore * minRel)
    return false;

  return true;
}

function isSafeToExecute(candidate) {
  if (!candidate)
    return false;

  if (candidate.dangerous && candidate.score < 0.90)
    return false;

  return candidate.score >= 0.75;
}

function scoreToBand(score) {
  if (score >= 0.90) return "excellent";
  if (score >= 0.75) return "strong";
  if (score >= 0.55) return "plausible";
  if (score >= 0.35) return "weak";
  return "hidden";
}
