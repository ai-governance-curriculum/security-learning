# Project 5: Security Operations Center for ML

**Duration**: 130 hours

## Goal

Stand up a SOC capable of detecting + responding to security incidents on an ML platform:
- 24/7 monitoring + alerting (rotated on-call)
- Detection rules: lateral movement, privilege escalation, data exfiltration, adversarial query patterns
- Response playbooks: incident classification, containment, recovery
- Threat intel: CISA KEV, vendor advisories, MITRE ATLAS for ML-specific threats
- Game days: quarterly tabletop + injected incidents

## Required components

1. **SIEM**: aggregate logs from K8s audit, Falco, Vault, model registry, service mesh
2. **Detection rules**: Sigma format; cover MITRE ATT&CK + MITRE ATLAS coverage
3. **SOAR**: automated response for known patterns (block IP, rotate compromised secret, isolate pod)
4. **Threat intel feed**: STIX/TAXII from CISA + commercial sources
5. **Tabletop scenarios**: 3 ML-specific (model theft, poisoning, adversarial DoS)
6. **Postmortem template**: blameless, action-oriented

## Cross-references

- engineer-solutions/mod-108 ex-09 (incident response game day)
- engineer-solutions/mod-108 ex-07 (alertmanager routing)
