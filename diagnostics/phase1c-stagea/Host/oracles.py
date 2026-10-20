"""Narrow A0/A1/A4 observations. No authority-mechanism conclusions."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

OBSERVED = "OBSERVED (NARROW PLATFORM RESULT)"
FALSIFIED = "FALSIFIED ASSUMPTION"
INCONCLUSIVE = "INCONCLUSIVE"
NOT_REACHED = "NOT REACHED"
BLOCKED_TERMINATION = "BLOCKED / TERMINATION UNVERIFIED"
BLOCKED_INTEGRITY = "BLOCKED / OBSERVATION INTEGRITY UNPROVEN"
NOT_CHARACTERIZED = "NOT CHARACTERIZED"


@dataclass(frozen=True)
class Verdict:
    category: str
    reason: str

    def record(self) -> dict[str, str]:
        return {"category": self.category, "reason": self.reason}


def a0_negative(scenario: str, evidence: dict[str, Any]) -> Verdict:
    if evidence.get("external_signal") is not None:
        return Verdict(FALSIFIED, "Negative control used an external signal")
    if not evidence.get("worker_launch") or not evidence.get("worker_exited"):
        return Verdict(INCONCLUSIVE, "Worker launch/exit not independently observed")
    required = {
        "a0-injected-error": "negative_injected",
        "a0-ordinary-exit": "negative_ordinary",
    }.get(scenario)
    if required is None or required not in evidence.get("markers", []):
        return Verdict(INCONCLUSIVE, "Expected control marker unavailable")
    return Verdict(OBSERVED, "Distinct non-kill control classified without crash claim")


def a0_external_kill(evidence: dict[str, Any]) -> Verdict:
    if not evidence.get("process_bound_signal_backend_verified"):
        return Verdict(BLOCKED_TERMINATION, "No independently validated process-bound host signal backend")
    if not (evidence.get("bound_target_identity")
            and evidence.get("externally_confirmed_sigkill")
            and evidence.get("worker_death_observed")
            and evidence.get("fresh_observer_identity")):
        return Verdict(BLOCKED_TERMINATION, "Identity, signal, death or fresh process unverified")
    return Verdict(OBSERVED, "External process death demonstrated; no database-write timing claim")


def a1_store(evidence: dict[str, Any]) -> Verdict:
    if not evidence.get("source_initially_absent"):
        return Verdict(INCONCLUSIVE, "Initial source root was not demonstrated absent")
    if "store_save_returned" not in evidence.get("markers", []):
        return Verdict(INCONCLUSIVE, "Worker did not report successful synthetic save")
    if not evidence.get("worker_exited"):
        return Verdict(INCONCLUSIVE, "Worker not independently confirmed quiescent")
    if not evidence.get("a4_integrity_verified"):
        return Verdict(BLOCKED_INTEGRITY, "A4 preservation/isolation is mandatory for A1")
    if evidence.get("observer_records") != 1 or not evidence.get("sentinel_matched"):
        return Verdict(INCONCLUSIVE, "Isolated fresh-process sentinel match not demonstrated")
    return Verdict(OBSERVED, "Synthetic SwiftData store opened on copy; no lifecycle proof")


def a4_known(evidence: dict[str, Any]) -> Verdict:
    if not evidence.get("worker_exited"):
        return Verdict(BLOCKED_INTEGRITY, "Cannot establish quiescence")
    if not evidence.get("source_copy_bytes_verified"):
        return Verdict(BLOCKED_INTEGRITY, "Copy/tree bytes not validated")
    if not evidence.get("original_unchanged"):
        return Verdict(BLOCKED_INTEGRITY, "Original artifacts changed during copy inspection")
    if not evidence.get("fresh_observer_identity"):
        return Verdict(INCONCLUSIVE, "Separate inspection process not verified")
    if not evidence.get("inspection_delta_recorded"):
        return Verdict(BLOCKED_INTEGRITY, "Inspection effects not distinguishable")
    return Verdict(OBSERVED, "Original preserved and observer effects separately inventoried")


def a4_missing(evidence: dict[str, Any]) -> Verdict:
    if not evidence.get("source_initially_absent"):
        return Verdict(INCONCLUSIVE, "Source absence not established before opening copy")
    if not evidence.get("source_still_absent"):
        return Verdict(BLOCKED_INTEGRITY, "Source store unexpectedly appeared")
    if not evidence.get("fresh_observer_identity") or not evidence.get("inspection_delta_recorded"):
        return Verdict(INCONCLUSIVE, "Observer identity or effects not independently recorded")
    if evidence.get("observer_records") != 0:
        return Verdict(FALSIFIED, "Synthetic missing-store control unexpectedly contains records")
    return Verdict(OBSERVED, "Absent source distinguished from observer-created copy")


def finalize(verdict: Verdict, details: dict[str, Any]) -> dict[str, Any]:
    return {
        "result": verdict.record(),
        "observations": details,
        "excluded_claims": [
            "Stage B", "positive lifecycle origin", "store correspondence",
            "atomic reference initialization", "multiple-context guard",
            "physical-device behavior", "ordinary mid-creation crash recovery",
            "production implementation readiness",
        ],
    }
