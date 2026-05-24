# Requirements — Compliance Framework

## FR-001: Data classification
Every dataset has labels: `data_class: pii | phi | confidential | public`.
Enforced via Kyverno on PV/PVC.

## FR-002: GDPR subject DELETE
API endpoint that propagates a user_id deletion across: warehouse, feature store, training data, model artifacts (where the user contributed labels).

## FR-003: GDPR subject EXPORT
API endpoint returning all data + predictions for a user_id within 30 days, in machine-readable format.

## FR-004: GDPR subject EXPLAIN
For a specific prediction, return: model version, input features, top SHAP contributions, decision threshold.

## FR-005: Audit log integrity
All security-relevant events (auth, secret access, model promotion, data access) recorded in tamper-evident chain.

## FR-006: Quarterly reports
Auto-generated per framework (GDPR, HIPAA, SOC 2): controls implemented, evidence of operation, exceptions noted.

## NFR-001: Subject request SLA
DELETE within 30 days (GDPR Art. 17); EXPORT within 30 days (Art. 20).
